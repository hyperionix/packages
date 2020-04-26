setfenv(1, require "sysapi-ns")
local Process = require "process.Process"
local ProcessEntity = hp.ProcessEntity
local EventChannel = hp.EventChannel

---@param context EntryExecutionContext
local NtWriteVirtualMemory_onEntry = function(context)
  if Process.isCurrentProcess(context.p.ProcessHandle) then
    context:skipExitHook()
  end
end

---@param context ExitExecutionContext
local NtWriteVirtualMemory_onExit = function(context)
  if context.retval == STATUS_SUCCESS then
    local size =
      tonumber(
      context.p.NumberOfBytesWritten ~= NULL and context.p.NumberOfBytesWritten[0] or context.p.NumberOfBytesToWrite
    )

    Event(
      "Interprocess Memory Write",
      {
        address = toaddress(context.p.BaseAddress),
        size = tonumber(size),
        sourceProcess = ProcessEntity.fromCurrent(),
        targetProcess = ProcessEntity.fromHandle(context.p.ProcessHandle)
      }
    ):send(EventChannel.file, EventChannel.splunk)
  end
end

Probe {
  name = "Interprocess Memory Write",
  hooks = {
    {
      name = "NtWriteVirtualMemory",
      onEntry = NtWriteVirtualMemory_onEntry,
      onExit = NtWriteVirtualMemory_onExit
    }
  }
}
