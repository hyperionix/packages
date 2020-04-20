setfenv(1, require "sysapi-ns")
local ProcessEntity = hp.ProcessEntity

Probe {
  name = "Interprocess Memory Allocation",
  hooks = {
    {
      name = "NtAllocateVirtualMemory",
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
              name = "Interprocess Memory Allocation",
              address = toaddress(context.p.BaseAddress[0]),
              size = tonumber(context.p.RegionSize[0]),
              protect = tonumber(context.p.Protect),
              sourceProcess = ProcessEntity.fromCurrent(),
              targetProcess = ProcessEntity.fromHandle(context.p.ProcessHandle)
            }:saveTo("splunk", "file")
          }
        }
      end
    }
  }
}
