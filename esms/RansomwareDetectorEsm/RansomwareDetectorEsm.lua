setfenv(1, require "sysapi-ns")
local Process = require "process.Process"

local EventChannel = hp.EventChannel
local LOG_LEVEL = 0
local CONSOLE_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.console)
local DBG_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.debug)
local LOG = DBG_LOG

Esm {
  name = "RansomwareDetectorEsm",
  probes = {
    {
      name = "ProcessCreateFromDownloadedFileEsm"
    },
    {
      name = "CryptoMonitorProbe"
    }
  },
  states = {
    {
      name = "initial",
      triggers = {
        {
          event = "ProcessCreateFromDownloadedFileEvent",
          action = function(state, entity, event)
            if entity.eid == event.process.eid then
              state:transition("SuspiciousProcessCreateState")
            end
          end
        }
      }
    },
    {
      name = "SuspiciousProcessCreateState",
      triggers = {
        {
          event = "CryptoKeyExportEvent",
          action = function(state, entity, event)
            if entity.eid == event.actorProcess.eid then
              Alert(
                "RansomwareDetectedEvent",
                {
                  process = event.actorProcess,
                  key = event.key,
                  keyType = event.type
                }
              ):send(EventChannel.splunk, EventChannel.file)

              local process = Process.open(event.actorProcess.pid, PROCESS_TERMINATE)
              if process then
                Event(
                  "RansomwareProcessTerminatedEvent",
                  {
                    process = event.actorProcess
                  }
                ):send(EventChannel.splunk, EventChannel.file)
                process:terminate()
              end
              state:finalize()
            end
          end
        },
        {
          event = "CryptoKeyImportEvent",
          action = function(state, entity, event)
          end
        },
        {
          event = "CryptoKeyExportEvent",
          action = function(state, entity, event)
          end
        }
      }
    }
  }
}
