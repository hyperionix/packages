setfenv(1, require "sysapi-ns")
local EventChannel = hp.EventChannel
local CurrentProcessEntity = hp.CurrentProcessEntity

local function getModuleFullPath(hmod)
  local size = 512

  while true do
    local buf = ffi.new("char[?]", size)

    local ret = ffi.C.GetModuleFileNameA(hmod, buf, size)
    if ret == 0 then
      -- error occured
      return ""
    end

    if ffi.C.GetLastError() == ERROR_INSUFFICIENT_BUFFER then
      size = size * 2
    else
      return ffi.string(buf, ret)
    end
  end
end

---@param context ExitExecutionContext
local function LdrLoadDll_onExit(context)
  if context.retval == STATUS_SUCCESS then
    Event(
      "ModuleLoadEvent",
      {
        module = getModuleFullPath(context.p.ModuleHandle[0]),
        process = CurrentProcessEntity
      }
    )
  end
end

---@param context EntryExecutionContext
local function LdrUnloadDll_onEntry(context)
  modPath = getModuleFullPath(context.p.ModuleHandle)
end

---@param context ExitExecutionContext
local function LdrUnloadDll_onExit(context)
  if context.retval == STATUS_SUCCESS then
    Event(
      "ModuleUnloadEvent",
      {
        module = modPath,
        process = CurrentProcessEntity
      }
    )
  end
end

Probe {
  name = "ExecutableModuleMonitorProbe",
  hooks = {
    {
      name = "LdrLoadDllHook",
      onEntry = function(context)
      end,
      onExit = LdrLoadDll_onExit
    },
    {
      name = "LdrUnloadDllHook",
      onEntry = LdrUnloadDll_onEntry,
      onExit = LdrUnloadDll_onExit
    }
  }
}
