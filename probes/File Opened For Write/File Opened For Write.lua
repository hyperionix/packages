setfenv(1, require "sysapi-ns")
local File = require "file.File"
local Handle = require "handle.Handle"
local ProcessEntity = hp.ProcessEntity
local FileEntity = hp.FileEntity
local EventChannel = hp.EventChannel
local band = bit.band
local string = string

local function IsWriteAccess(access)
  return band(access, FILE_WRITE_DATA) ~= 0 or band(access, FILE_APPEND_DATA) ~= 0 or band(access, GENERIC_WRITE) ~= 0
end

---@param context EntryExecutionContext
local function onEntry(context)
  if not IsWriteAccess(context.p.DesiredAccess) then
    context:skipExitHook()
  end
end

---@param context ExitExecutionContext
local function onExit(context)
  if context.retval == STATUS_SUCCESS then
    local f = File.fromHandle(context.p.FileHandle[0])
    if f then
      if f.deviceType == FILE_DEVICE_DISK then
        Event(
          "File Opened For Write",
          {
            file = FileEntity.fromTable(
              {
                fullPath = string.fromUS(context.p.ObjectAttributes.ObjectName),
                handle = context.p.FileHandle[0]
              }
            ),
            process = ProcessEntity.fromCurrent()
          }
        ):send(EventChannel.file, EventChannel.splunk)
      end
    end
  end
end

Probe {
  name = "File Opened For Write",
  hooks = {
    {
      name = "NtCreateFile",
      onEntry = onEntry,
      onExit = onExit
    },
    {
      name = "NtOpenFile",
      onEntry = onEntry,
      onExit = onExit
    }
  }
}
