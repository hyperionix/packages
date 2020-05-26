setfenv(1, require "sysapi-ns")
local File = require "file.File"
local Handle = require "handle.Handle"
local stringify = require "utils.stringify"
local ProcessEntity = hp.ProcessEntity
local FileEntity = hp.FileEntity
local EventChannel = hp.EventChannel
local band = bit.band
local string = string
local toaddress = toaddress

---@param context EntryExecutionContext
local function onEntry(context)
  -- Is write access
  if File.isWriteAccess(context.p.DesiredAccess) then
    local options
    if context.hook == "NtCreateFile" then
      options = context.p.CreateOptions
    else
      options = context.p.OpenOptions
    end

    -- Is File
    if band(options, FILE_NON_DIRECTORY_FILE) ~= 0 then
      return -- onExit needed
    end
  end

  context:skipExitHook()
end

---@param context ExitExecutionContext
local function onExit(context)
  if context.retval == STATUS_SUCCESS then
    local file = File.fromHandle(context.p.FileHandle[0])
    if file then
      if file.deviceType == FILE_DEVICE_DISK then
        local opened = false
        if context.hook == "NtOpenFile" then
          opened = true
        else
          local info = context.p.IoStatusBlock.Information
          if info == FILE_OPENED then
            opened = true
          end
        end
        local eventName
        if opened then
          eventName = "File Opened For Write"
        else
          eventName = "File Created For Write"
        end

        local fileEntity =
          FileEntity.fromTable(
          {
            fullPath = string.fromUS(context.p.ObjectAttributes.ObjectName),
            handle = context.p.FileHandle[0]
          }
        )

        fileEntity:calcHashes({"md5"})
        Event(
          eventName,
          {
            file = fileEntity,
            process = ProcessEntity.fromCurrent()
          }
        )
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
