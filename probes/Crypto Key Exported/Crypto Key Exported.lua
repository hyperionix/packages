setfenv(1, require "sysapi-ns")
local ProcessEntity = hp.ProcessEntity
local CryptoKeyEntity = hp.CryptoKeyEntity

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
      "Crypto Key Exported",
      {
        process = ProcessEntity.fromCurrent(),
        key = CryptoKeyEntity.fromHandle(context.p.hKey, CRYPT_EXPORTABLE)
      }
    )
  end
end

Probe {
  name = "Crypto Key Exported",
  hooks = {
    {
      name = "CryptExportKey",
      onEntry = CryptExportKey_onEntry,
      onExit = CryptExportKey_onExit
    }
  }
}
