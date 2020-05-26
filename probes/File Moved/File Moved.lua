setfenv(1, require "sysapi-ns")
local File = require "file.File"
local EventChannel = hp.EventChannel
local ProcessEntity = hp.ProcessEntity
local FileEntity = hp.FileEntity

---@param context EntryExecutionContext
local function onEntry(context)
  if
    context.p.FileInformationClass == ffi.C.FileRenameInformation or
      context.p.FileInformationClass == ffi.C.FileRenameInformationEx
   then
    srcFileEntity = FileEntity.fromHandle(context.p.FileHandle)
  else
    -- skip unwanted operations
    context:skipExitHook()
  end
end

---@param context ExitExecutionContext
local function onExit(context)
  if context.retval == STATUS_SUCCESS then
    local f = File.fromHandle(context.p.FileHandle)
    if not f:isDirectory() then
      Event(
        "File Moved",
        {
          srcFile = srcFileEntity,
          dstFile = FileEntity.fromSysapiFile(f):calcHashes({"md5"}),
          process = ProcessEntity.fromCurrent()
        }
      )
    end
  end
end

Probe {
  name = "File Moved",
  hooks = {
    {
      name = "NtSetInformationFile",
      onEntry = onEntry,
      onExit = onExit
    }
  }
}
