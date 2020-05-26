--[[
  Use sysapi library
]]
setfenv(1, require "sysapi-ns")
local File = require "file.File"

--[[
  hp library utilities
]]
local EntityCache = hp.EntityCache
local ProcessEntity = hp.ProcessEntity
local FileEntity = hp.FileEntity
local EventChannel = hp.EventChannel

--[[
  Cache local functions and objects
]]
local band = bit.band
local LOG_LEVEL = 1
local CONSOLE_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.console)
local DBG_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.debug)
local LOG = DBG_LOG

--[[
  Script level initialization
]]
local HandleCache = EntityCache.new("FileHandles", 64)
local CurrentProcessEntity = ProcessEntity.fromCurrent()
local BROWSER_NAMES = {
  firefox = true,
  chrome = true,
  iexplore = true,
  microsoftedge = true,
  microsoftedgecp = true
}

-- Is the probe loaded into a browser process?
local IS_BROWSER_PROCESS = BROWSER_NAMES[CurrentProcessEntity.backingFile.path.basename:lower()] or false

--[[
  Probe callbacks
]]
---@param context EntryExecutionContext
local NtCreateFile_NtOpenFile_onEntry = function(context)
  if not IS_BROWSER_PROCESS then
    context:skipExitHook()
    return
  end

  -- Is write access
  if File.isWriteAccess(context.p.DesiredAccess) then
    local options
    if context.hook == "NtCreateFile" then
      options = context.p.CreateOptions
    else
      options = context.p.OpenOptions
    end

    -- Is File
    if band(options, FILE_NON_DIRECTORY_FILE) ~= 0 then
      return -- onExit needed
    end
  end

  context:skipExitHook()
end

---@param context ExitExecutionContext
local NtCreateFile_NtOpenFile_onExit = function(context)
  if context.retval == STATUS_SUCCESS then
    local file = File.fromHandle(context.p.FileHandle[0])
    if file then
      if file.deviceType == FILE_DEVICE_DISK then
        local opened = false
        if context.hook == "NtOpenFile" then
          opened = true
        else
          local info = context.p.IoStatusBlock.Information
          if info == FILE_OPENED then
            opened = true
          end
        end
        local eventName
        if opened then
          eventName = "File Opened For Write"
        else
          eventName = "File Created For Write"
        end

        local fileEntity =
          FileEntity.fromTable(
          {
            fullPath = string.fromUS(context.p.ObjectAttributes.ObjectName),
            handle = context.p.FileHandle[0]
          }
        )

        Event(
          eventName,
          {
            file = fileEntity,
            process = CurrentProcessEntity
          }
        ):send(-EventChannel.esm)

        LOG:dbg("111: ", fileEntity.path.full)
        HandleCache:store({fileEntity = fileEntity, written = false}, context.p.FileHandle[0])
      end
    end
  end
end

---@param context EntryExecutionContext
local NtWriteFile_onEntry = function(context)
  if not IS_BROWSER_PROCESS then
    return
  end

  local flowData = HandleCache:lookup(context.p.FileHandle)
  if flowData then
    if flowData.written then
      return
    else
      -- Generate `Write` event
      Event(
        "File Write",
        {
          process = CurrentProcessEntity,
          file = flowData.fileEntity
        }
      ):send(-EventChannel.esm)
      LOG:dbg("222: ", flowData.fileEntity.path.full)
      -- Set `written` flag to prevent multiple `Write` events generation as it is unecessary in our case
      flowData.written = true
      HandleCache:store(flowData, context.p.FileHandle)
    end
  end
end

---@param context EntryExecutionContext
local NtClose_onEntry = function(context)
  if not IS_BROWSER_PROCESS then
    return
  end

  local flowData = HandleCache:lookup(context.p.Handle)
  if flowData and flowData.written then
    LOG:dbg("333: ", flowData.fileEntity.path.full)
    HandleCache:delete(context.p.Handle)
    local fileEntity = FileEntity.fromHandle(context.p.Handle):calcHashes({"md5"})
    LOG:dbg("444: ", fileEntity.path.full)
    Event("File Created By Browser", {process = CurrentProcessEntity, file = fileEntity})
  end
end

--[[
  Probe declaration
]]
Probe {
  name = "File Created By Browser",
  hooks = {
    {
      name = "NtCreateFile",
      onEntry = NtCreateFile_NtOpenFile_onEntry,
      onExit = NtCreateFile_NtOpenFile_onExit
    },
    {
      name = "NtOpenFile",
      onEntry = NtCreateFile_NtOpenFile_onEntry,
      onExit = NtCreateFile_NtOpenFile_onExit
    },
    {
      name = "NtWriteFile",
      onEntry = NtWriteFile_onEntry
    },
    {
      name = "NtClose",
      onEntry = NtClose_onEntry
    }
  }
}
