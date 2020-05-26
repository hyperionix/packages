local EventChannel = hp.EventChannel

local LOG_LEVEL = 0
local CONSOLE_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.console)
local DBG_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.debug)
local LOG = CONSOLE_LOG

Esm {
  name = "Suspicious Process Created 1",
  probes = {
    {
      name = "File Created By Browser"
    },
    {
      name = "File Moved"
    },
    {
      name = "Process Created"
    }
  },
  states = {
    {
      name = "initial",
      triggers = {
        {
          event = "File Created By Browser",
          action = function(state, entity, event)
            if entity.eid == event.file.eid then
              state:transition("File Created By Browser")
            end
          end
        }
      }
    },
    {
      name = "File Created By Browser",
      triggers = {
        {
          event = "File Moved",
          action = function(state, entity, event)
            if entity.eid == event.srcFile.eid then
              -- DBG:dbg("222")
              -- We don't care about source file entity as it was renamed
              state:finalize()
              -- File created by browser was moved. Create entity in current state for new file entity
              local state = createEntityState(event.dstFile)
              state:transition("File Created By Browser")
            end
          end
        },
        {
          event = "File Copied",
          action = function(state, entity, event)
            if entity.eid == event.srcFile.eid then
              -- File created by browser was copied. Create entity in current state for new file entity
              local state = createEntityState(event.dstFile)
              state:transition("File Created By Browser")
            end
          end
        },
        {
          event = "File Deleted",
          action = function(state, entity, event)
            -- File created by browser was deleted. Forget about it.
            state:finalize()
          end
        },
        {
          event = "Process Created",
          action = function(state, entity, event)
            -- A process was created from the file entity. Consider such processes as potential suspicious.
            if entity.eid == event.newProcess.backingFile.eid then
              Alert(
                "Suspicious Process Created",
                {
                  reason = "Downloaded From Internet",
                  process = event.newProcess,
                  parentProcess = event.parentProcess
                }
              ):send(EventChannel.splunk, EventChannel.file)
            end
          end
        }
      }
    }
  }
}
