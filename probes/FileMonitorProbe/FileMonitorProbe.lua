setfenv(1, require "sysapi-ns")
local File = require "file.File"
local FilePath = require "file.Path"
local time = require "time.time"
local EntityCache = hp.EntityCache
local FileEntity = hp.FileEntity
local EventChannel = hp.EventChannel
local band = bit.band
local string = string

local CurrentProcessEntity = hp.CurrentProcessEntity

local LOG_LEVEL = 1
local CONSOLE_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.console)
local DBG_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.debug)
local LOG = CONSOLE_LOG

local AllFilesCache = EntityCache.new("AllFilesCache", 64)
local FileSizeCache = EntityCache.new("FileSizeCache", 64)

---@param context EntryExecutionContext
local NtCreateFile_NtOpenFile_onEntry = function(context)
end

---@param context ExitExecutionContext
local NtCreateFile_NtOpenFile_onExit = function(context)
  if NT_SUCCESS(context.retval) then
    local file = File.fromHandle(context.p.FileHandle[0])
    if file and file.deviceType == FILE_DEVICE_DISK and not file:isDirectory() then
      -- check for ADS creation
      if context.hook == "NtCreateFile" then
        local info = context.p.IoStatusBlock.Information
        if info == FILE_CREATED or info == FILE_OVERWRITTEN then
          local filePath = FilePath.fromString(file.fullPath)
          if string.find(filePath.basename .. filePath.ext, ":") then
            Event(
              "ADSCreateEvent",
              {
                actorProcess = CurrentProcessEntity,
                file = FileEntity.fromSysapiFile(file)
              }
            ):send(EventChannel.splunk)
          end
        end
      end

      local options
      if context.hook == "NtCreateFile" then
        options = context.p.CreateOptions
      else
        options = context.p.OpenOptions
      end

      local flowData = {
        name = file.fullPath,
        devChars = file.deviceCharacteristics,
        isDelOnClose = band(options, FILE_DELETE_ON_CLOSE) ~= 0,
        isDelPending = false
      }

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
      Event(
        "FileWriteEvent",
        {
          actorProcess = CurrentProcessEntity,
          file = FileEntity.fromHandle(context.p.FileHandle)
        }
      ):send(EventChannel.splunk)
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
local NtSetInformationFile_onEntry = function(context)
  local flowData = AllFilesCache:lookup(context.p.FileHandle)
  if flowData then
    local infoClass = context.p.FileInformationClass

    if infoClass == ffi.C.FileRenameInformation or infoClass == ffi.C.FileRenameInformationEx then
      srcFileEntity = FileEntity.fromHandle(context.p.FileHandle)
      return
    elseif infoClass == ffi.C.FileDispositionInformation or infoClass == ffi.C.FileDispositionInformationEx then
      return
    elseif infoClass == ffi.C.FileBasicInformation then
      local file = File.fromHandle(context.p.FileHandle)
      timeBefore = {
        createTime = file.createTime,
        writeTime = file.writeTime
      }
      return
    end
  end

  context:skipExitHook()
end

---@param context ExitExecutionContext
local NtSetInformationFile_onExit = function(context)
  local infoClass = context.p.FileInformationClass

  if infoClass == ffi.C.FileRenameInformation or infoClass == ffi.C.FileRenameInformationEx then
    if NT_SUCCESS(context.retval) then
      -- TODO: update name in cache
      Event(
        "FileMoveEvent",
        {
          actorProcess = CurrentProcessEntity,
          file = srcFileEntity,
          dstFile = FileEntity.fromHandle(context.p.FileHandle)
        }
      ):send(EventChannel.splunk)
    end
  elseif infoClass == ffi.C.FileDispositionInformation or infoClass == ffi.C.FileDispositionInformationEx then
    if NT_SUCCESS(context.retval) then
      local flowData = AllFilesCache:lookup(context.p.FileHandle)
      if flowData then
        local isDelOnClose = flowData.isDelOnClose
        local isDelPending = flowData.isDelPending

        if context.p.FileInformationClass == ffi.C.FileDispositionInformation then
          local info = ffi.cast("PFILE_DISPOSITION_INFORMATION", context.p.FileInformation)
          isDelPending = info.DeleteFile == 1
        else
          -- TODO: handle FILE_DISPOSITION_POSIX_SEMANTICS flag
          local info = ffi.cast("PFILE_DISPOSITION_INFORMATION_EX", context.p.FileInformation)
          local isDel = band(info.Flags, FILE_DISPOSITION_DELETE) ~= 0
          -- FILE_DISPOSITION_DELETE flag action depends on FILE_DISPOSITION_ON_CLOSE flag
          if band(info.Flags, FILE_DISPOSITION_ON_CLOSE) ~= 0 then
            isDelOnClose = isDel
          else
            isDelPending = isDel
          end
        end

        -- update cache entry only if it is changed
        if flowData.isDelOnClose ~= isDelOnClose or flowData.isDelPending ~= isDelPending then
          flowData.isDelOnClose = isDelOnClose
          flowData.isDelPending = isDelPending
          AllFilesCache:store(flowData, context.p.FileHandle)
        end
      end
    end
  elseif infoClass == ffi.C.FileBasicInformation then
    if NT_SUCCESS(context.retval) then
      local info = ffi.cast("PFILE_BASIC_INFORMATION", context.p.FileInformation)
      local writeTime = info.LastWriteTime.QuadPart
      local createTime = info.CreationTime.QuadPart

      if createTime > 0 or writeTime > 0 then
        local fileEntity = FileEntity.fromHandle(context.p.FileHandle)

        if createTime > 0 then
          Event(
            "FileCreationTimeModificationEvent",
            {
              actorProcess = CurrentProcessEntity,
              file = fileEntity,
              tsBefore = timeBefore.createTime,
              tsAfter = time.toUnixTimestamp(createTime)
            }
          ):send(EventChannel.splunk)
        end

        if writeTime > 0 then
          Event(
            "FileLastWriteTimeModificationEvent",
            {
              actorProcess = CurrentProcessEntity,
              file = fileEntity,
              tsBefore = timeBefore.writeTime,
              tsAfter = time.toUnixTimestamp(writeTime)
            }
          ):send(EventChannel.splunk)
        end
      end
    end
  end
end

---@param context EntryExecutionContext
local NtClose_onEntry = function(context)
  local flowData = AllFilesCache:lookup(context.p.Handle)
  if flowData then
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
            "FileCopyEvent",
            {
              actorProcess = CurrentProcessEntity,
              file = srcFileEntity,
              dstFile = dstFileEntity
            }
          ):send(EventChannel.splunk)

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
                  actorProcess = CurrentProcessEntity,
                  file = srcFileEntity,
                  dstFile = dstFileEntity,
                  remoteType = remoteType
                }
              ):send(EventChannel.splunk)
            end
          end
        end
        FileSizeCache:delete(cacheKey)
      end
    end

    if flowData.isDelOnClose or flowData.isDelPending then
      -- TODO: check that all open handles for the file have been closed
      -- if FILE_DISPOSITION_POSIX_SEMANTICS is not set
      Event(
        "FileDeleteEvent",
        {
          actorProcess = CurrentProcessEntity,
          file = FileEntity.fromHandle(context.p.Handle)
        }
      ):send(EventChannel.splunk)
    end

    AllFilesCache:delete(context.p.Handle)
  end
end

Probe {
  name = "FileMonitorProbe",
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
      -- onExit = NtWriteFile_onExit
    },
    {
      name = "NtReadFile",
      onEntry = NtReadFile_onEntry
      -- onExit = NtReadFile_onExit
    },
    {
      name = "NtSetInformationFile",
      onEntry = NtSetInformationFile_onEntry,
      onExit = NtSetInformationFile_onExit
    },
    {
      name = "NtClose",
      onEntry = NtClose_onEntry
    }
  }
}
