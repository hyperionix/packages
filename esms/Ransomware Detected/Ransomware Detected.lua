setfenv(1, require "sysapi-ns")
local Process = require "process.Process"

local EventChannel = hp.EventChannel
local LOG_LEVEL = 0
local CONSOLE_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.console)
local DBG_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.debug)
local LOG = DBG_LOG

Esm {
  name = "Ransomware Detected",
  probes = {
    {
      name = "Suspicious Process Created 1"
    },
    {
      name = "Crypto Key Exported"
    }
  },
  states = {
    {
      name = "initial",
      triggers = {
        {
          event = "Suspicious Process Created",
          action = function(state, entity, event)
            if entity.eid == event.process.eid then
              state:transition("Suspicious Process Created")
            end
          end
        }
      }
    },
    {
      name = "Suspicious Process Created",
      triggers = {
        {
          event = "Export Crypto Key",
          action = function(state, entity, event)
            if entity.eid == event.process.eid then
              Alert(
                "Ransomware Detected",
                {
                  process = event.process,
                  key = event.key,
                  keyType = event.type
                }
              ):send(EventChannel.splunk, EventChannel.file)

              local process = Process.open(event.process.pid, PROCESS_TERMINATE)
              if process then
                Event(
                  "Ransomware Process Terminate",
                  {
                    process = event.process
                  }
                ):send(EventChannel.splunk, EventChannel.file)
                process:terminate()
              end
              state:finalize()
            end
          end
        }
      }
    }
  }
}
