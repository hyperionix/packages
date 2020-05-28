setfenv(1, require "sysapi-ns")
local File = require "file.File"
local stringify = require "utils.stringify"
local EntityCache = hp.EntityCache
local ProcessEntity = hp.ProcessEntity
local FileEntity = hp.FileEntity
local EventChannel = hp.EventChannel
local band = bit.band

local LOG_LEVEL = 1
local CONSOLE_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.console)
local DBG_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.debug)
local LOG = DBG_LOG

local AllFilesCache = EntityCache.new("AllFilesCache", 64)
local FileSizeCache = EntityCache.new("FileSizeCache", 64)

--[[
  For source file access is 
]]
---@param context EntryExecutionContext
local NtCreateFile_NtOpenFile_onEntry = function(context)
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

  context:skipExitHook()
end

---@param context ExitExecutionContext
local NtCreateFile_NtOpenFile_onExit = function(context)
  if NT_SUCCESS(context.retval) then
    local file = File.fromHandle(context.p.FileHandle[0])
    if file and file.deviceType == FILE_DEVICE_DISK then
      local flowData = {
        name = file.fullPath,
        devChars = file.deviceCharacteristics
      }

      LOG:dbg(context.hook, flowData.name)
      AllFilesCache:store(flowData, context.p.FileHandle[0])
    end
  end
end

---@param context EntryExecutionContext
local NtWriteFile_onEntry = function(context)
  local flowData = AllFilesCache:lookup(context.p.FileHandle)
  if flowData then
    if not flowData.write then
      flowData.write = true
      AllFilesCache:store(flowData, context.p.FileHandle)
    end
    LOG:dbg(context.hook, flowData.name)
  end
end

---@param context EntryExecutionContext
local NtReadFile_onEntry = function(context)
  local flowData = AllFilesCache:lookup(context.p.FileHandle)
  if flowData then
    if not flowData.read then
      flowData.read = true
      AllFilesCache:store(flowData, context.p.FileHandle)
    end
    LOG:dbg(context.hook, flowData.name)
  end
end

---@param context EntryExecutionContext
local NtClose_onEntry = function(context)
  local flowData = AllFilesCache:lookup(context.p.Handle)
  if flowData then
    LOG:dbg(context.hook, flowData.name)
    if flowData.read or flowData.write then
      local file = File.fromHandle(context.p.Handle)
      local cacheKey = ffi.cast("void*", file.size)
      local sizeData = FileSizeCache:lookup(cacheKey)
      if not sizeData then
        FileSizeCache:store({name = flowData.name, devChars = flowData.devChars}, cacheKey)
      else
        local srcFilePath, dstFilePath, srcFile, dstFile, dstDevChars
        if flowData.read then
          -- The last closed file is a source file
          srcFilePath = file.fullPath
          dstFilePath = sizeData.name
          srcFile = file
          dstDevChars = sizeData.devChars
        else
          -- The last closed file is a destination file
          srcFilePath = sizeData.name
          dstFilePath = file.fullPath
          dstFile = file
          dstDevChars = flowData.devChars
        end

        if srcFilePath and dstFilePath and srcFilePath ~= dstFilePath then
          -- small optimization to prevent creation both entites from paths which is slower than from sysapi File object
          local srcFileEntity, dstFileEntity
          if srcFile then
            dstFile = File.fromFullPath(dstFilePath)
            srcFileEntity = FileEntity.fromSysapiFile(srcFile)
            dstFileEntity = FileEntity.fromSysapiFile(dstFile)
          else
            assert(dstFile)
            srcFile = File.fromFullPath(srcFilePath)
            srcFileEntity = FileEntity.fromSysapiFile(srcFile)
            dstFileEntity = FileEntity.fromSysapiFile(dstFile)
          end

          LOG:dbg(srcFilePath, " -> ", dstFilePath)

          Event(
            "File Copied",
            {
              process = ProcessEntity.fromCurrent(),
              srcFile = srcFileEntity,
              dstFile = dstFileEntity
            }
          )

          if dstDevChars then
            local remoteType
            if band(dstDevChars, FILE_REMOVABLE_MEDIA) ~= 0 then
              remoteType = "Removable"
            elseif band(dstDevChars, FILE_REMOTE_DEVICE) ~= 0 then
              remoteType = "Network"
            end

            if remoteType then
              Event(
                "File Copied On Remote",
                {
                  process = ProcessEntity.fromCurrent(),
                  srcFile = srcFileEntity,
                  dstFile = dstFileEntity,
                  remoteType = remoteType
                }
              ):send(EventChannel.file, EventChannel.splunk)
            end
          end
        end
        FileSizeCache:delete(cacheKey)
      end
    end
    AllFilesCache:delete(context.p.Handle)
  end
end

Probe {
  name = "File Copied",
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
      name = "NtReadFile",
      onEntry = NtReadFile_onEntry
    },
    {
      name = "NtClose",
      onEntry = NtClose_onEntry
    }
  }
}
