local EventChannel = hp.EventChannel

Esm {
  name = "TestEsm",
  probes = {},
  states = {
    {
      name = "initial",
      triggers = {
        {
          eventName = "FileWriteEvent",
          action = function(state, event)
            state:transition(event.file.eid, "FileModifiedState", {foo = 100})
          end
        }
      }
    },
    {
      name = "FileModifiedState",
      triggers = {
        {
          eventName = "FileMoveEvent",
          action = function(state, event)
            state:transition(event.dstFile.eid, "FileModifiedState")
          end,
          keyFn = function(event)
            return event.file.eid
          end
        },
        {
          eventName = "FileCopyEvent",
          action = function(state, event)
            state:spawn(event.dstFile.eid, "FileModifiedState")
          end,
          keyFn = function(event)
            return event.file.eid
          end
        },
        {
          eventName = "ProcessCreateEvent",
          action = function(state, event)
            event:send(EventChannel.splunk)
          end,
          keyFn = function(event)
            return event.process.backingFile.eid
          end
        }
      }
    }
  }
}
