setfenv(1, require "sysapi-ns")
local ProcessEntity = hp.ProcessEntity
local FileEntity = hp.FileEntity
local band = bit.band

local function IsWriteAccess(access)
  return band(access, FILE_WRITE_DATA) ~= 0 or band(access, FILE_APPEND_DATA) ~= 0 or band(access, 0x40000000) ~= 0
end

local function onEntry(context)
  if IsWriteAccess(context.p.DesiredAccess) then
    return true
  end
end

local function onExit(context)
  if context.r.eax ~= 0 then
    return
  end

  return {
    events = {
      Event {
        name = "File Opened For Write",
        file = FileEntity.fromPath(string.fromUS(context.p.ObjectAttributes.ObjectName)),
        process = ProcessEntity.fromCurrent()
      }:saveTo("file", "splunk")
    }
  }
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
