setfenv(1, require "sysapi-ns")
local File = require "file.File"
local ProcessEntity = hp.ProcessEntity
local FileEntity = hp.FileEntity
local EventChannel = hp.EventChannel

---@param context EntryExecutionContext
local NtWriteFile_onEntry = function(context)
  local file = File.fromHandle(context.p.FileHandle)
  if file.deviceType == FILE_DEVICE_DISK then
    local fileEntity = FileEntity.fromSysapiFile(file)
    Event(
      "File Write",
      {
        file = fileEntity,
        process = ProcessEntity.fromCurrent(),
        size = context.p.Length,
        handle = context.p.FileHandle
      }
    )
  end
end

Probe {
  name = "File Write",
  hooks = {
    {
      name = "NtWriteFile",
      onEntry = NtWriteFile_onEntry
    }
  }
}
