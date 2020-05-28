setfenv(1, require "sysapi-ns")
local ProcessEntity = hp.ProcessEntity
local CryptoKeyEntity = hp.CryptoKeyEntity

---@param context EntryExecutionContext
local CryptImportKey_onEntry = function(context)
end

---@param context ExitExecutionContext
local CryptImportKey_onExit = function(context)
  if context.retval ~= 0 then
    Event(
      "Crypto Key Imported",
      {
        process = ProcessEntity.fromCurrent(),
        key = CryptoKeyEntity.fromHandle(context.p.phKey[0], context.p.dwFlags)
      }
    )
  end
end

Probe {
  name = "Crypto Key Imported",
  hooks = {
    {
      name = "CryptImportKey",
      onEntry = CryptImportKey_onEntry,
      onExit = CryptImportKey_onExit
    }
  }
}
