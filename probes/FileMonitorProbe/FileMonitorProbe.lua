setfenv(1, require "sysapi-ns")
local File = require "file.File"
local time = require "time.time"
local SharedTable = hp.SharedTable
local FileEntity = hp.FileEntity
local EventChannel = hp.EventChannel
local band = bit.band

local CurrentProcessEntity = hp.CurrentProcessEntity

local LOG_LEVEL = 1
local CONSOLE_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.console)
local DBG_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.debug)
local LOG = DBG_LOG

local AllFilesCache = SharedTable.new("AllFilesCache", "number", 64)
local FileSizeCache = SharedTable.new("FileSizeCache", "number", 64)

---@param context EntryExecutionContext
local NtCreateFile_NtOpenFile_onEntry = function(context)
end

---@param context ExitExecutionContext
local NtCreateFile_NtOpenFile_onExit = function(context)
  if NT_SUCCESS(context.retval) then
    local file = File.fromHandle(context.p.FileHandle[0])
    if file and file.deviceType == FILE_DEVICE_DISK and not file:isDirectory() then
      -- check for ADS creation
      if context.hook == "NtCreateFileHook" then
        local info = context.p.IoStatusBlock.Information
        if info == FILE_CREATED or info == FILE_OVERWRITTEN then
          -- detecting ADS by ":" (ignoring ":" after drive letter)
          local pos = file.fullPath:find(":", 4)
          if pos then
            Event(
              "ADSCreateEvent",
              {
                actorProcess = CurrentProcessEntity,
                file = FileEntity.fromSysapiFile(file):addHashes():build()
              }
            )

            local adsName = file.fullPath:sub(pos + 1)
            if adsName == "Zone.Identifier" then
              Event(
                "FileDownloadEvent",
                {
                  actorProcess = CurrentProcessEntity,
                  file = FileEntity.fromFullPath(file.fullPath:sub(1, pos - 1)):addHashes():build()
                }
              )
            end
          end
        end
      end

      local options
      if context.hook == "NtCreateFileHook" then
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
      Event(
        "FileWriteEvent",
        {
          actorProcess = CurrentProcessEntity,
          file = FileEntity.fromTable({handle = context.p.FileHandle, fullPath = flowData.name}):build()
        }
      )
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
local NtSetInformationFile_onEntry = function(context)
  local flowData = AllFilesCache:get(context.p.FileHandle)
  if flowData then
    local infoClass = context.p.FileInformationClass

    if infoClass == ffi.C.FileRenameInformation or infoClass == ffi.C.FileRenameInformationEx then
      srcFileEntity = FileEntity.fromHandle(context.p.FileHandle):build()
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
          dstFile = FileEntity.fromHandle(context.p.FileHandle):build()
        }
      )
    end
  elseif infoClass == ffi.C.FileDispositionInformation or infoClass == ffi.C.FileDispositionInformationEx then
    if NT_SUCCESS(context.retval) then
      local flowData = AllFilesCache:get(context.p.FileHandle)
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
          AllFilesCache:add(context.p.FileHandle, flowData)
        end
      end
    end
  elseif infoClass == ffi.C.FileBasicInformation then
    if NT_SUCCESS(context.retval) then
      local info = ffi.cast("PFILE_BASIC_INFORMATION", context.p.FileInformation)
      local writeTime = info.LastWriteTime.QuadPart
      local createTime = info.CreationTime.QuadPart

      if createTime > 0 or writeTime > 0 then
        local fileEntity = FileEntity.fromHandle(context.p.FileHandle):build()

        if createTime > 0 then
          Event(
            "FileCreationTimeModificationEvent",
            {
              actorProcess = CurrentProcessEntity,
              file = fileEntity,
              tsBefore = timeBefore.createTime,
              tsAfter = time.toUnixTimestamp(createTime)
            }
          )
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
          )
        end
      end
    end
  end
end

---@param context EntryExecutionContext
local NtClose_onEntry = function(context)
  local flowData = AllFilesCache:get(context.p.Handle)
  if flowData then
    if flowData.read or flowData.write then
      local file = File.fromTable({handle = context.p.Handle, fullPath = flowData.name})
      local cacheKey = ffi.cast("void*", file.size)
      local sizeData = FileSizeCache:get(cacheKey)
      if not sizeData then
        -- Create file entity for closed file here
        local fileEntity = FileEntity.fromSysapiFile(file):build()
        FileSizeCache:add(cacheKey, {name = flowData.name, devChars = flowData.devChars, fileEntity = fileEntity})
      else
        local srcFilePath, dstFilePath, srcFile, dstFile, dstDevChars, dstFileEntity, srcFileEntity
        if flowData.read then
          -- The last closed file is a source file
          srcFilePath = file.fullPath
          srcFile = file
          dstFilePath = sizeData.name
          dstFileEntity = sizeData.fileEntity
          dstDevChars = sizeData.devChars
        else
          -- The last closed file is a destination file
          srcFilePath = sizeData.name
          srcFileEntity = sizeData.fileEntity
          dstFilePath = file.fullPath
          dstFile = file
          dstDevChars = flowData.devChars
        end

        if srcFilePath and dstFilePath and srcFilePath ~= dstFilePath then
          -- small optimization to prevent creation both entites from paths which is slower than from sysapi File object
          if srcFile then
            -- typical case for file copy
            -- in this case we already have dstFileEntity created on close of the file
            srcFileEntity = FileEntity.fromSysapiFile(srcFile):build()
          else
            -- in this case we have srcFileEntity
            assert(dstFile)
            dstFileEntity = FileEntity.fromSysapiFile(dstFile):build()
          end

          LOG:dbg(srcFilePath, " -> ", dstFilePath)

          Event(
            "FileCopyEvent",
            {
              actorProcess = CurrentProcessEntity,
              file = srcFileEntity,
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
                  actorProcess = CurrentProcessEntity,
                  file = srcFileEntity,
                  dstFile = dstFileEntity,
                  remoteType = remoteType
                }
              )
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
          file = FileEntity.fromHandle(context.p.Handle):build()
        }
      )
    end

    AllFilesCache:delete(context.p.Handle)
  end
end

Probe {
  name = "FileMonitorProbe",
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
      -- onExit = NtWriteFile_onExit
    },
    {
      name = "NtReadFileHook",
      onEntry = NtReadFile_onEntry
      -- onExit = NtReadFile_onExit
    },
    {
      name = "NtSetInformationFileHook",
      onEntry = NtSetInformationFile_onEntry,
      onExit = NtSetInformationFile_onExit
    },
    {
      name = "NtCloseHook",
      onEntry = NtClose_onEntry
    }
  }
}
