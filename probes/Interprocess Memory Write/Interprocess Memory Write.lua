setfenv(1, require "sysapi-ns")
local ProcessEntity = hp.ProcessEntity

Probe {
  name = "Interprocess Memory Write",
  hooks = {
    {
      name = "NtWriteVirtualMemory",
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

        local size =
          context.p.NumberOfBytesWritten ~= NULL and context.p.NumberOfBytesWritten[0] or context.p.NumberOfBytesToWrite
        return {
          events = {
            Event {
              name = "Interprocess Memory Write",
              address = toaddress(context.p.BaseAddress),
              size = tonumber(size),
              sourceProcess = ProcessEntity.fromCurrent(),
              targetProcess = ProcessEntity.fromHandle(context.p.ProcessHandle)
            }:saveTo("splunk", "file")
          }
        }
      end
    }
  }
}
