local EventChannel = hp.EventChannel

local LOG_LEVEL = 0
local CONSOLE_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.console)
local DBG_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.debug)
local LOG = CONSOLE_LOG

Esm {
  name = "ProcessCreateFromDownloadedFileEsm",
  probes = {
    {
      name = "FileMonitorProbe"
    },
    {
      name = "ProcessCreateProbe"
    }
  },
  states = {
    {
      name = "initial",
      triggers = {
        {
          event = "FileDownloadEvent",
          action = function(state, entity, event)
            if entity.eid == event.file.eid then
              state:transition("FileDownloadState")
            end
          end
        }
      }
    },
    {
      name = "FileDownloadState",
      triggers = {
        {
          event = "FileMoveEvent",
          action = function(state, entity, event)
            if entity.eid == event.srcFile.eid then
              -- DBG:dbg("222")
              -- We don't care about source file entity as it was renamed
              state:finalize()
              -- File created by browser was moved. Create entity in current state for new file entity
              local state = createEntityState(event.dstFile)
              state:transition("FileDownloadState")
            end
          end
        },
        {
          event = "FileCopyEvent",
          action = function(state, entity, event)
            if entity.eid == event.srcFile.eid then
              -- File created by browser was copied. Create entity in current state for new file entity
              local state = createEntityState(event.dstFile)
              state:transition("FileDownloadState")
            end
          end
        },
        {
          event = "FileDeleteEvent",
          action = function(state, entity, event)
            -- File created by browser was deleted. Forget about it.
            state:finalize()
          end
        },
        {
          event = "ProcessCreateEvent",
          action = function(state, entity, event)
            -- A process was created from the file entity. Consider such processes as potential suspicious.
            if entity.eid == event.process.backingFile.eid then
              Alert(
                "ProcessCreateFromDownloadedFileEvent",
                {
                  actorProcess = event.actorProcess,
                  process = event.process
                }
              )
            end
          end
        }
      }
    }
  }
}
