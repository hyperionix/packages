setfenv(1, require "sysapi-ns")
local File = require "file.File"
local stringify = require "utils.stringify"
local SharedTable = hp.SharedTable
local CurrentProcessEntity = hp.CurrentProcessEntity
local FileEntity = hp.FileEntity
local EventChannel = hp.EventChannel
local band = bit.band

local LOG_LEVEL = 1
local CONSOLE_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.console)
local DBG_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.debug)
local LOG = DBG_LOG

local AllFilesCache = SharedTable.new("AllFilesCache", "number", 64)
local FileSizeCache = SharedTable.new("FileSizeCache", "number", 64)

--[[
  For source file access is 
]]
---@param context EntryExecutionContext
local NtCreateFile_NtOpenFile_onEntry = function(context)
  local options
  if context.hook == "NtCreateFileHook" then
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

      AllFilesCache:add(context.p.FileHandle[0], flowData)
    end
  end
end

---@param context EntryExecutionContext
local NtWriteFile_onEntry = function(context)
  local flowData = AllFilesCache:get(context.p.FileHandle)
  if flowData then
    if not flowData.write then
      flowData.write = true
      AllFilesCache:add(context.p.FileHandle, flowData)
    end
    LOG:dbg(context.hook, flowData.name)
  end
end

---@param context EntryExecutionContext
local NtReadFile_onEntry = function(context)
  local flowData = AllFilesCache:get(context.p.FileHandle)
  if flowData then
    if not flowData.read then
      flowData.read = true
      AllFilesCache:add(context.p.FileHandle, flowData)
    end
    LOG:dbg(context.hook, flowData.name)
  end
end

---@param context EntryExecutionContext
local NtClose_onEntry = function(context)
  local flowData = AllFilesCache:get(context.p.Handle)
  if flowData then
    LOG:dbg(context.hook, flowData.name)
    if flowData.read or flowData.write then
      local file = File.fromHandle(context.p.Handle)
      local cacheKey = ffi.cast("void*", file.size)
      local sizeData = FileSizeCache:get(cacheKey)
      if not sizeData then
        FileSizeCache:add(cacheKey, {name = flowData.name, devChars = flowData.devChars})
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
            srcFileEntity = FileEntity.fromSysapiFile(srcFile):build()
            dstFileEntity = FileEntity.fromSysapiFile(dstFile):build()
          else
            assert(dstFile)
            srcFile = File.fromFullPath(srcFilePath)
            srcFileEntity = FileEntity.fromSysapiFile(srcFile):build()
            dstFileEntity = FileEntity.fromSysapiFile(dstFile):build()
          end

          LOG:dbg(srcFilePath, " -> ", dstFilePath)

          Event(
            "FileCopyEvent",
            {
              process = CurrentProcessEntity,
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
                "FileCopyOnRemoteEvent",
                {
                  process = CurrentProcessEntity,
                  srcFile = srcFileEntity,
                  dstFile = dstFileEntity,
                  remoteType = remoteType
                }
              ):send(EventChannel.file)
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
  name = "FileCopyProbe",
  hooks = {
    {
      name = "NtCreateFileHook",
      onEntry = NtCreateFile_NtOpenFile_onEntry,
      onExit = NtCreateFile_NtOpenFile_onExit
    },
    {
      name = "NtOpenFileHook",
      onEntry = NtCreateFile_NtOpenFile_onEntry,
      onExit = NtCreateFile_NtOpenFile_onExit
    },
    {
      name = "NtWriteFileHook",
      onEntry = NtWriteFile_onEntry
    },
    {
      name = "NtReadFileHook",
      onEntry = NtReadFile_onEntry
    },
    {
      name = "NtCloseHook",
      onEntry = NtClose_onEntry
    }
  }
}
