setfenv(1, require "sysapi-ns")

local ProcessEntity = hp.ProcessEntity
local EventChannel = hp.EventChannel
local band = bit.band
local string = string

local ffi = require "ffi"

pcall(
  ffi.cdef,
  [[
  NTSTATUS NtQueryInformationProcess(
    IN HANDLE           ProcessHandle,
    IN PROCESSINFOCLASS ProcessInformationClass,
    OUT PVOID           ProcessInformation,
    IN ULONG            ProcessInformationLength,
    OUT PULONG          ReturnLength
  );]]
)

pcall(ffi.cdef, [[
    HMODULE GetModuleHandleA(
      LPCSTR lpModuleName
    );
  ]])

pcall(
  ffi.cdef,
  [[
  typedef struct _PROCESS_BASIC_INFORMATION2 {
    PVOID Reserved1;
    struct _PEB* PebBaseAddress;
    PVOID Reserved2[2];
    ULONG_PTR UniqueProcessId;
    PVOID Reserved3;
  } PROCESS_BASIC_INFORMATION2;
  ]]
)

local ntdll = ffi.load("ntdll")

---@param context EntryExecutionContext
local function onEntry(context)
  local pbi = ffi.new("PROCESS_BASIC_INFORMATION2[1]")
  local retLength = ffi.new("ULONG[1]")
  local status = ntdll.NtQueryInformationProcess(ffi.C.GetCurrentProcess(), 0, pbi, ffi.sizeof(pbi[0]), retLength)

  local baseAddressOriginal = toaddress(ffi.C.GetModuleHandleA(nil))
  local baseAddressFromPeb = toaddress(pbi[0].PebBaseAddress.ImageBaseAddress)

  assert(baseAddressOriginal == baseAddressFromPeb)

  Event(
    "Symbols Test",
    {
      baseAddressOriginal = ("0x%X"):format(baseAddressOriginal),
      baseAddressFromPeb = ("0x%X"):format(baseAddressFromPeb),
      dll = string.fromUS(context.p.DllName),
      process = ProcessEntity.fromCurrent()
    }
  ):send(EventChannel.file, EventChannel.splunk)
end

Probe {
  name = "Symbols Test",
  hooks = {
    {
      name = "LdrpLoadDll",
      onEntry = onEntry
    }
  }
}
