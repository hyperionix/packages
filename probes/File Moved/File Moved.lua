setfenv(1, require "sysapi-ns")
local File = require "file.File"
local EventChannel = hp.EventChannel
local ProcessEntity = hp.ProcessEntity

---@param context EntryExecutionContext
local function onEntry(context)
  if
    context.p.FileInformationClass == ffi.C.FileRenameInformation or
      context.p.FileInformationClass == ffi.C.FileRenameInformationEx
   then
    local f = File.fromHandle(context.p.FileHandle)
    fullPathBefore = f.fullPath
  else
    -- skip unwanted operations
    context:skipExitHook()
  end
end

---@param context ExitExecutionContext
local function onExit(context)
  if context.retval == STATUS_SUCCESS then
    local f = File.fromHandle(context.p.FileHandle)

    Event(
      f:isDirectory() and "Entire Directory Moved" or "File Moved",
      {
        before = fullPathBefore,
        after = f.fullPath,
        process = ProcessEntity.fromCurrent()
      }
    ):send(EventChannel.file, EventChannel.splunk)
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
