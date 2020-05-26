setfenv(1, require "sysapi-ns")

local HIDDEN_PROCESS = "notepad.exe"

---@param context EntryExecutionContext
local function onEntry(context)
  -- TODO: support rest process-specific information classes
  if
    context.p.SystemInformationClass ~= ffi.C.SystemProcessInformation and
      context.p.SystemInformationClass ~= ffi.C.SystemExtendedProcessInformation
   then
    -- skip unwanted operations
    context:skipExitHook()
  end
end

local hiddenProcName = HIDDEN_PROCESS:lower()

---@param context ExitExecutionContext
local function onExit(context)
  if context.retval == STATUS_SUCCESS then
    local info = ffi.cast("PSYSTEM_PROCESS_INFORMATION", context.p.SystemInformation)

    while info.NextEntryOffset ~= 0 do
      local prev = info
      info = ffi.cast("PSYSTEM_PROCESS_INFORMATION", ffi.cast("PUCHAR", info) + info.NextEntryOffset)

      local imageName = string.fromUS(info.ImageName):lower()

      if imageName == hiddenProcName then
        -- unlink hidden process entry
        if (info.NextEntryOffset == 0) then
          prev.NextEntryOffset = 0
        else
          prev.NextEntryOffset = prev.NextEntryOffset + info.NextEntryOffset
        end
      end
    end
  end
end

Probe {
  name = "Hide Process",
  hooks = {
    {
      name = "NtQuerySystemInformation",
      onEntry = onEntry,
      onExit = onExit
    }
  }
}
