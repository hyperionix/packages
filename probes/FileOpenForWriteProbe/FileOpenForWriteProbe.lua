setfenv(1, require "sysapi-ns")
local File = require "file.File"
local Handle = require "handle.Handle"
local stringify = require "utils.stringify"
local FileEntity = hp.FileEntity
local EventChannel = hp.EventChannel
local CurrentProcessEntity = hp.CurrentProcessEntity
local band = bit.band
local string = string
local toaddress = toaddress

---@param context EntryExecutionContext
local function onEntry(context)
  -- Is write access
  if File.isWriteAccess(context.p.DesiredAccess) then
    local options
    if context.hook == "NtCreateFileHook" then
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
        if context.hook == "NtOpenFileHook" then
          opened = true
        else
          local info = context.p.IoStatusBlock.Information
          if info == FILE_OPENED then
            opened = true
          end
        end
        local eventName
        if opened then
          eventName = "FileOpenForWriteEvent"
        else
          eventName = "FileCreateForWriteEvent"
        end

        local fileEntity =
          FileEntity.fromTable(
          {
            fullPath = string.fromUS(context.p.ObjectAttributes.ObjectName),
            handle = context.p.FileHandle[0]
          }
        ):build()

        Event(
          eventName,
          {
            file = fileEntity,
            actorProcess = CurrentProcessEntity
          }
        )
      end
    end
  end
end

Probe {
  name = "FileOpenForWriteProbe",
  hooks = {
    {
      name = "NtCreateFileHook",
      onEntry = onEntry,
      onExit = onExit
    },
    {
      name = "NtOpenFileHook",
      onEntry = onEntry,
      onExit = onExit
    }
  }
}
