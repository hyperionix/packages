setfenv(1, require "sysapi-ns")
local ProcessEntity = hp.ProcessEntity
local CurrentProcessEntity = hp.CurrentProcessEntity
local EventChannel = hp.EventChannel

---@param context EntryExecutionContext
local NtCreateUserProcess_onEntry = function(context)
end

---@param context ExitExecutionContext
local NtCreateUserProcess_onExit = function(context)
  if context.retval == STATUS_SUCCESS then
    local processEntity = ProcessEntity.fromHandle(context.p.ProcessHandle[0]):build()
    Event(
      "ProcessCreateEvent",
      {
        process = processEntity,
        actorProcess = CurrentProcessEntity
      }
    )
  end
end

Probe {
  name = "ProcessCreateProbe",
  hooks = {
    {
      name = "NtCreateUserProcessHook",
      onEntry = NtCreateUserProcess_onEntry,
      onExit = NtCreateUserProcess_onExit
    }
  }
}
