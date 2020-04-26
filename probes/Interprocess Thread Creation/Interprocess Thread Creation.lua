setfenv(1, require "sysapi-ns")
local Process = require "process.Process"
local ProcessEntity = hp.ProcessEntity
local EventChannel = hp.EventChannel

---@param context EntryExecutionContext
local NtCreateThreadEx_onEntry = function(context)
  if Process.isCurrentProcess(context.p.ProcessHandle) then
    context:skipExitHook()
  end
end

---@param context ExitExecutionContext
local NtCreateThreadEx_onExit = function(context)
  if context.retval == STATUS_SUCCESS then
    Event(
      "Interprocess Thread Creation",
      {
        startRoutine = toaddress(context.p.StartRoutine),
        sourceProcess = ProcessEntity.fromCurrent(),
        targetProcess = ProcessEntity.fromHandle(context.p.ProcessHandle)
      }
    ):send(EventChannel.file, EventChannel.splunk)
  end
end

Probe {
  name = "Interprocess Thread Creation",
  hooks = {
    {
      name = "NtCreateThreadEx",
      onEntry = NtCreateThreadEx_onEntry,
      onExit = NtCreateThreadEx_onExit
    }
  }
}
