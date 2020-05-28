setfenv(1, require "sysapi-ns")
local Crypto = require "crypto.Crypto"
local stringify = require "utils.stringify"
local ProcessEntity = hp.ProcessEntity
local CryptoKeyEntity = hp.CryptoKeyEntity
local EventChannel = hp.EventChannel

---@param context EntryExecutionContext
local CryptGenKey_onEntry = function(context)
end

---@param context ExitExecutionContext
local CryptGenKey_onExit = function(context)
  if context.retval ~= 0 then
    Event(
      "Crypto Key Generated",
      {
        process = ProcessEntity.fromCurrent(),
        key = CryptoKeyEntity.fromHandle(context.p.phKey[0], context.p.dwFlags)
      }
    )
  end
end

Probe {
  name = "Crypto Key Generated",
  hooks = {
    {
      name = "CryptGenKey",
      onEntry = CryptGenKey_onEntry,
      onExit = CryptGenKey_onExit
    }
  }
}
