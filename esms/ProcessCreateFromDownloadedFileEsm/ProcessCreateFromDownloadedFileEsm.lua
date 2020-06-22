local EventChannel = hp.EventChannel

Esm {
  name = "ProcessCreateFromDownloadedFileEsm",
  -- if > 0 turns on ESM debug mode
  debug = 0,
  probes = {
    {
      name = "FileMonitorProbe"
    },
    {
      name = "ProcessMonitorProbe"
    }
  },
  states = {
    {
      name = "initial",
      triggers = {
        {
          eventName = "FileDownloadEvent",
          -- initial event doesn't need keyFn.  It applies to any matching event regardless of its key value
          action = function(state, event)
            -- Transition to the FileDownloadState with the given id if it doesn't yet exist
            state:transition(event.file.eid, "FileDownloadedState")
          end
        }
      }
    },
    {
      name = "FileDownloadedState",
      triggers = {
        {
          eventName = "ProcessCreateEvent",
          -- A process was created from the file entity. Consider such processes to be potentially suspicious and generate an event
          action = function(state, event)
            Event("ProcessCreateFromDownloadedFileEvent"):send(EventChannel.splunk)
          end,
          -- When provided keyFn will be used to compute the event key and
          -- would only trigger actions on those states that match it
          keyFn = function(event)
            return event.process.backingFile.eid
          end
        },
        {
          eventName = "FileDeleteEvent",
          action = function(state, event)
            -- File created by browser was deleted. Forget about it.
            state:finalize()
          end,
          keyFn = function(event)
            return event.file.eid
          end
        },
        {
          eventName = "FileCopyEvent",
          action = function(state, event)
            -- File created by browser was copied.
            -- state:spawn() is just like transition(), but will create
            -- a copy of the ESM state with the original one still being available.
            state:spawn(event.dstFile.eid, "FileDownloadedState")
          end,
          keyFn = function(event)
            return event.file.eid
          end
        },
        {
          eventName = "FileMoveEvent",
          action = function(state, event)
            -- Transition the current state object to the same state with new ID and data
            state:transition(event.dstFile.eid, "FileDownloadedState")
          end,
          keyFn = function(event)
            return event.file.eid
          end
        }
      }
    }
  }
}
