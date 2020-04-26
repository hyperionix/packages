setfenv(1, require "sysapi-ns")
local ProcessEntity = hp.ProcessEntity
local FileEntity = hp.FileEntity
local EventChannel = hp.EventChannel
local band = bit.band
local string = string

local function IsWriteAccess(access)
  return band(access, FILE_WRITE_DATA) ~= 0 or band(access, FILE_APPEND_DATA) ~= 0 or band(access, 0x40000000) ~= 0
end

---@param context EntryExecutionContext
local function onEntry(context)
  if not IsWriteAccess(context.p.DesiredAccess) then
    context:skipExitHook()
  end
end

---@param context ExitExecutionContext
local function onExit(context)
  if context.retval == 0 then
    Event(
      "File Opened For Write",
      {
        file = FileEntity.fromPath(string.fromUS(context.p.ObjectAttributes.ObjectName)),
        process = ProcessEntity.fromCurrent()
      }
    ):send(EventChannel.file, EventChannel.splunk)
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
