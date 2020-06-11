setfenv(1, require "sysapi-ns")
local FileEntity = hp.FileEntity
local EventChannel = hp.EventChannel
local CurrentProcessEntity = hp.CurrentProcessEntity
local Handle = require "handle.Handle"
local File = require "file.File"

---@param context EntryExecutionContext
local NtClose_onEntry = function(context)
  local h = Handle.create(context.p.Handle)
  if h.objectType == "File" then
    if File.isWriteAccess(h.objectAccess) then
      local file = File.fromHandle(h.handle)
      if not file:isDirectory() then
        local fileEntity = FileEntity.fromSysapiFile(file):addHashes({"md5"}):build()
        if fileEntity then
          Event(
            "FileCloseEvent",
            {
              file = fileEntity,
              process = CurrentProcessEntity
            }
          )
        end
      end
    end
  end
end

Probe {
  name = "FileCloseProbe",
  hooks = {
    {
      name = "NtCloseHook",
      onEntry = NtClose_onEntry
    }
  }
}
