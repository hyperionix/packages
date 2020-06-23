setfenv(1, require "sysapi-ns")
local Process = require "process.Process"
local ProcessEntity = hp.ProcessEntity
local CurrentProcessEntity = hp.CurrentProcessEntity
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
      "InterprocessMemoryWriteEvent",
      {
        address = toaddress(context.p.BaseAddress),
        size = tonumber(size),
        actorProcess = CurrentProcessEntity,
        targetProcess = ProcessEntity.fromHandle(context.p.ProcessHandle):build()
      }
    )
  end
end

Probe {
  name = "InterprocessMemoryWriteProbe",
  hooks = {
    {
      name = "NtWriteVirtualMemoryHook",
      onEntry = NtWriteVirtualMemory_onEntry,
      onExit = NtWriteVirtualMemory_onExit
    }
  }
}
