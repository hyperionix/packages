setfenv(1, require "sysapi-ns")
local Process = require "process.Process"
local ProcessEntity = hp.ProcessEntity
local EventChannel = hp.EventChannel

---@param context EntryExecutionContext
local NtAllocateVirtualMemory_onEntry = function(context)
  if Process.isCurrentProcess(context.p.ProcessHandle) then
    context:skipExitHook()
  end
end

---@param context ExitExecutionContext
local NtAllocateVirtualMemory_onExit = function(context)
  if context.retval == STATUS_SUCCESS then
    Event(
      "Interprocess Memory Allocation",
      {
        address = toaddress(context.p.BaseAddress[0]),
        size = tonumber(context.p.RegionSize[0]),
        protect = tonumber(context.p.Protect),
        sourceProcess = ProcessEntity.fromCurrent(),
        targetProcess = ProcessEntity.fromHandle(context.p.ProcessHandle)
      }
    ):send(EventChannel.file, EventChannel.splunk)
  end
end

Probe {
  name = "Interprocess Memory Allocations",
  hooks = {
    {
      name = "NtAllocateVirtualMemory",
      onEntry = NtAllocateVirtualMemory_onEntry,
      onExit = NtAllocateVirtualMemory_onExit
    }
  }
}