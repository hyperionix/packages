setfenv(1, require "sysapi-ns")
local File = require "file.File"
local FileEntity = hp.FileEntity
local EventChannel = hp.EventChannel
local CurrentProcessEntity = hp.CurrentProcessEntity

---@param context EntryExecutionContext
local NtWriteFile_onEntry = function(context)
  local file = File.fromHandle(context.p.FileHandle)
  if file.deviceType == FILE_DEVICE_DISK then
    local fileEntity = FileEntity.fromSysapiFile(file):build()
    Event(
      "FileWriteEvent",
      {
        file = fileEntity,
        actorProcess = CurrentProcessEntity,
        size = context.p.Length
      }
    )
  end
end

Probe {
  name = "FileWriteProbe",
  hooks = {
    {
      name = "NtWriteFileHook",
      onEntry = NtWriteFile_onEntry
    }
  }
}
