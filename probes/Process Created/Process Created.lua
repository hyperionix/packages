setfenv(1, require "sysapi-ns")
local ProcessEntity = hp.ProcessEntity

Probe {
  name = "Process Created",
  hooks = {
    {
      name = "NtCreateUserProcess",
      onEntry = function(context)
        return true
      end,
      onExit = function(context)
        if context.r.eax ~= 0 then
          return
        end

        return {
          events = {
            Event {
              name = "Process Created",
              newProcess = ProcessEntity.fromHandle(context.p.ProcessHandle[0]),
              parentProcess = ProcessEntity.fromCurrent()
            }:saveTo("splunk", "file")
          }
        }
      end
    }
  }
}
