setfenv(1, require "sysapi-ns")
local FileEntity = hp.FileEntity
local ProcessEntity = hp.ProcessEntity
local EventChannel = hp.EventChannel
local Handle = require "handle.Handle"
local File = require "file.File"

---@param context EntryExecutionContext
local NtClose_onEntry = function(context)
  local h = Handle.create(context.p.Handle)
  if h.objectType == "File" then
    if File.isWriteAccess(h.objectAccess) then
      local file = File.fromHandle(h.handle)
      if not file:isDirectory() then
        local fileEntity = FileEntity.fromSysapiFile(file)
        if fileEntity then
          fileEntity:calcHashes({"md5"})

          Event(
            "File Closed",
            {
              file = fileEntity,
              process = ProcessEntity.fromCurrent()
            }
          )
        end
      end
    end
  end
end

Probe {
  name = "File Closed",
  hooks = {
    {
      name = "NtClose",
      onEntry = NtClose_onEntry
    }
  }
}
