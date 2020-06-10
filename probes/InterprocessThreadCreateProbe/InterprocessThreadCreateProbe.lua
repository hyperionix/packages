setfenv(1, require "sysapi-ns")
local Process = require "process.Process"
local ProcessEntity = hp.ProcessEntity
local CurrentProcessEntity = hp.CurrentProcessEntity
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
      "InterprocessThreadCreateEvent",
      {
        startRoutine = toaddress(context.p.StartRoutine),
        actorProcess = CurrentProcessEntity,
        targetProcess = ProcessEntity.fromHandle(context.p.ProcessHandle):build()
      }
    ):send(EventChannel.file, EventChannel.splunk)
  end
end

Probe {
  name = "InterprocessThreadCreateProbe",
  hooks = {
    {
      name = "NtCreateThreadExHook",
      onEntry = NtCreateThreadEx_onEntry,
      onExit = NtCreateThreadEx_onExit
    }
  }
}
