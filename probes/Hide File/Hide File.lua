setfenv(1, require "sysapi-ns")
local File = require "file.File"
local FilePath = require "file.Path"
local string = string

hp.cdef [[
  typedef struct _FILE_BOTH_DIR_INFORMATION {
    ULONG         NextEntryOffset;
    ULONG         FileIndex;
    LARGE_INTEGER CreationTime;
    LARGE_INTEGER LastAccessTime;
    LARGE_INTEGER LastWriteTime;
    LARGE_INTEGER ChangeTime;
    LARGE_INTEGER EndOfFile;
    LARGE_INTEGER AllocationSize;
    ULONG         FileAttributes;
    ULONG         FileNameLength;
    ULONG         EaSize;
    BYTE          ShortNameLength;
    WCHAR         ShortName[12];
    WCHAR         FileName[1];
  } FILE_BOTH_DIR_INFORMATION, *PFILE_BOTH_DIR_INFORMATION;

  typedef struct _FILE_ID_BOTH_DIR_INFO {
    ULONG         NextEntryOffset;
    ULONG         FileIndex;
    LARGE_INTEGER CreationTime;
    LARGE_INTEGER LastAccessTime;
    LARGE_INTEGER LastWriteTime;
    LARGE_INTEGER ChangeTime;
    LARGE_INTEGER EndOfFile;
    LARGE_INTEGER AllocationSize;
    ULONG         FileAttributes;
    ULONG         FileNameLength;
    ULONG         EaSize;
    BYTE          ShortNameLength;
    WCHAR         ShortName[12];
    LARGE_INTEGER FileId;
    WCHAR         FileName[1];
  } FILE_ID_BOTH_DIR_INFO, *PFILE_ID_BOTH_DIR_INFO;
]]

local HIDDEN_FILE = "C:\\Windows\\notepad.exe"

local hiddenFullPath = FilePath.fromString(HIDDEN_FILE:lower())
local hiddenFullDir = hiddenFullPath.drive .. hiddenFullPath.dir:sub(1, -2)
local hiddenFileName = hiddenFullPath.basename .. hiddenFullPath.ext

---@param context EntryExecutionContext
local function onEntry(context)
  local dir = File.fromHandle(context.p.FileHandle)

  -- skip queries on unwanted directories
  if dir.fullPath:lower() ~= hiddenFullDir then
    context:skipExitHook()
  end
end

---@param context ExitExecutionContext
local function onExit(context)
  if context.retval == STATUS_SUCCESS then
    local infoType
    if context.p.FileInformationClass == ffi.C.FileBothDirectoryInformation then
      infoType = ffi.typeof("PFILE_BOTH_DIR_INFORMATION")
    elseif context.p.FileInformationClass == ffi.C.FileIdBothDirectoryInformation then
      infoType = ffi.typeof("PFILE_ID_BOTH_DIR_INFO")
    else
      -- TODO: other information classes are not currently supported, support them
      return
    end

    local info = ffi.cast(infoType, context.p.FileInformation)
    local usFileName = ffi.new("UNICODE_STRING")

    while info.NextEntryOffset ~= 0 do
      local prev = info
      info = ffi.cast(infoType, ffi.cast("PUCHAR", info) + info.NextEntryOffset)

      -- info.FileName can be not null-terminated, so init UNICODE_STRING
      usFileName.Length = info.FileNameLength
      usFileName.MaximumLength = info.FileNameLength
      usFileName.Buffer = info.FileName
      local fileName = string.fromUS(usFileName):lower()

      if fileName == hiddenFileName then
        -- unlink hidden file entry
        if (info.NextEntryOffset == 0) then
          prev.NextEntryOffset = 0
        else
          prev.NextEntryOffset = prev.NextEntryOffset + info.NextEntryOffset
        end
        break
      end
    end
  end
end

Probe {
  name = "Hide File",
  hooks = {
    {
      name = "NtQueryDirectoryFile",
      onEntry = onEntry,
      onExit = onExit
    },
    {
      name = "NtQueryDirectoryFileEx",
      onEntry = onEntry,
      onExit = onExit
    }
  }
}
