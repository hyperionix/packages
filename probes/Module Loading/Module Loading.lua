setfenv(1, require "sysapi-ns")
local EventChannel = hp.EventChannel
local ProcessEntity = hp.ProcessEntity

hp.cdef [[
  DWORD GetModuleFileNameA(
    HMODULE hModule,
    LPSTR   lpFilename,
    DWORD   nSize
  );
]]

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
      "Module Loaded",
      {
        module = getModuleFullPath(context.p.ModuleHandle[0]),
        process = ProcessEntity.fromCurrent()
      }
    ):send(EventChannel.file, EventChannel.splunk)
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
      "Module Unloaded",
      {
        module = modPath,
        process = ProcessEntity.fromCurrent()
      }
    ):send(EventChannel.file, EventChannel.splunk)
  end
end

Probe {
  name = "Module Loading",
  hooks = {
    {
      name = "LdrLoadDll",
      onEntry = function(context)
      end,
      onExit = LdrLoadDll_onExit
    },
    {
      name = "LdrUnloadDll",
      onEntry = LdrUnloadDll_onEntry,
      onExit = LdrUnloadDll_onExit
    }
  }
}
