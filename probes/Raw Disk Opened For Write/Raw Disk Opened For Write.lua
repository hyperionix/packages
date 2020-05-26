setfenv(1, require "sysapi-ns")
local _ = hp.underscore
local ProcessEntity = hp.ProcessEntity
local band = bit.band

local DISK_NAME_PATTERNS = {
  "\\??\\PhysicalDrive%d",
  "\\Device\\Harddisk%d\\DR%d",
  "\\GLOBAL??\\PhysicalDrive%d",
  "\\??\\%a:"
}

local function IsDiskDevice(name)
  return _.detect(
    DISK_NAME_PATTERNS,
    function(pattern)
      return name:find(pattern)
    end
  )
end

local function IsWriteAccess(access)
  return band(access, FILE_WRITE_DATA) ~= 0 or band(access, FILE_APPEND_DATA) ~= 0 or band(access, GENERIC_WRITE) ~= 0
end

local function onEntry(context)
  local access = context.p.DesiredAccess
  if IsWriteAccess(access) then
    targetName = string.fromUS(context.p.ObjectAttributes.ObjectName)
    if IsDiskDevice(targetName) then
      return true
    end
  end
end

local function onExit(context)
  if context.r.eax ~= 0 then
    return
  end

  return {
    events = {
      Event {
        name = "Raw Disk Opened For Write",
        targetName = targetName,
        process = ProcessEntity.fromCurrent()
      }:saveTo("splunk", "file")
    }
  }
end

Probe {
  name = "Raw Disk Opened For Write",
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
