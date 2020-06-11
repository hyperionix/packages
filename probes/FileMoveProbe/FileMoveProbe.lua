setfenv(1, require "sysapi-ns")
local File = require "file.File"
local EventChannel = hp.EventChannel
local FileEntity = hp.FileEntity
local CurrentProcessEntity = hp.CurrentProcessEntity

---@param context EntryExecutionContext
local function onEntry(context)
  if
    context.p.FileInformationClass == ffi.C.FileRenameInformation or
      context.p.FileInformationClass == ffi.C.FileRenameInformationEx
   then
    srcFileEntity = FileEntity.fromHandle(context.p.FileHandle):build()
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
        "FileMoveEvent",
        {
          srcFile = srcFileEntity,
          dstFile = FileEntity.fromSysapiFile(f):build(),
          actorProcess = CurrentProcessEntity
        }
      )
    end
  end
end

Probe {
  name = "FileMoveProbe",
  hooks = {
    {
      name = "NtSetInformationFileHook",
      onEntry = onEntry,
      onExit = onExit
    }
  }
}
