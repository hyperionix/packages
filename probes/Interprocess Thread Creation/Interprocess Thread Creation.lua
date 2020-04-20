setfenv(1, require "sysapi-ns")
local ProcessEntity = hp.ProcessEntity

Probe {
  name = "Interprocess Thread Creation",
  hooks = {
    {
      name = "NtCreateThreadEx",
      onEntry = function(context)
        if ffi.C.GetProcessId(context.p.ProcessHandle) == ffi.C.GetCurrentProcessId() then
          return
        end
        return true
      end,
      onExit = function(context)
        if context.r.eax ~= 0 then
          return
        end

        return {
          events = {
            Event {
              name = "Interprocess Thread Creation",
              startRoutine = toaddress(context.p.StartRoutine),
              sourceProcess = ProcessEntity.fromCurrent(),
              targetProcess = ProcessEntity.fromHandle(context.p.ProcessHandle)
            }:saveTo("splunk", "file")
          }
        }
      end
    }
  }
}
