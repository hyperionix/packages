setfenv(1, require "sysapi-ns")
local Process = require "process.Process"

local EventChannel = hp.EventChannel
local LOG_LEVEL = 0
local CONSOLE_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.console)
local DBG_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.debug)
local LOG = DBG_LOG

Esm {
  name = "RansomwareDetectorEsm",
  debug = 0,
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
          eventName = "ProcessCreateFromDownloadedFileEvent",
          action = function(state, event)
            state:transition(event.process.pid, "SuspiciousProcessCreateState")
          end
        }
      }
    },
    {
      name = "SuspiciousProcessCreateState",
      triggers = {
        {
          eventName = "CryptoKeyExportEvent",
          action = function(state, event)
            Alert(
              "RansomwareDetectedEvent",
              {
                process = event.actorProcess,
                key = event.key,
                keyType = event.type
              }
            ):send(EventChannel.splunk)
            local process = Process.open(event.actorProcess.pid, PROCESS_TERMINATE)
            if process then
              Event(
                "RansomwareProcessTerminatedEvent",
                {
                  process = event.actorProcess
                }
              ):send(EventChannel.splunk)
              process:terminate()
            end
            state:finalize()
          end,
          keyFn = function(event)
            return event.actorProcess.pid
          end
        }
      }
    }
  }
}
