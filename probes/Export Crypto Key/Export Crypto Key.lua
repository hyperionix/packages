setfenv(1, require "sysapi-ns")
local stringify = require "utils.stringify"
local ProcessEntity = hp.ProcessEntity
local EventChannel = hp.EventChannel
local base64 = hp.base64

---@param context EntryExecutionContext
local CryptExportKey_onEntry = function(context)
  if context.p.pbData == ffi.NULL then
    context:skipExitHook()
  end
end

---@param context ExitExecutionContext
local CryptExportKey_onExit = function(context)
  if context.retval ~= 0 then
    Event(
      "Export Crypto Key",
      {
        process = ProcessEntity.fromCurrent(),
        key = base64.enc(ffi.string(context.p.pbData, tonumber(context.p.pdwDataLen[0]))),
        type = stringify.value(tonumber(context.p.dwBlobType), "KEYBLOB_TYPE")
      }
    )
  end
end

Probe {
  name = "Export Crypto Key",
  hooks = {
    {
      name = "CryptExportKey",
      onEntry = CryptExportKey_onEntry,
      onExit = CryptExportKey_onExit
    }
  }
}
