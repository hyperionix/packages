setfenv(1, require "sysapi-ns")
local ProcessEntity = hp.ProcessEntity
local EventChannel = hp.EventChannel

---@param context EntryExecutionContext
local NtCreateUserProcess_onEntry = function(context)
end

---@param context ExitExecutionContext
local NtCreateUserProcess_onExit = function(context)
  if context.retval == STATUS_SUCCESS then
    Event(
      "Process Created",
      {
        newProcess = ProcessEntity.fromHandle(context.p.ProcessHandle[0]),
        parentProcess = ProcessEntity.fromCurrent()
      }
    ):send(EventChannel.file, EventChannel.splunk)
  end
end

Probe {
  name = "Process Created",
  hooks = {
    {
      name = "NtCreateUserProcess",
      onEntry = NtCreateUserProcess_onEntry,
      onExit = NtCreateUserProcess_onExit
    }
  }
}
