setfenv(1, require "sysapi-ns")
local EventChannel = hp.EventChannel
local CryptoKeyEntity = hp.CryptoKeyEntity

local CurrentProcessEntity = hp.CurrentProcessEntity

local LOG_LEVEL = 0
local CONSOLE_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.console)
local DBG_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.debug)
local LOG = CONSOLE_LOG_LOG

---@param context EntryExecutionContext
local CryptGenKey_onEntry = function(context)
end

---@param context ExitExecutionContext
local CryptGenKey_onExit = function(context)
  if context.retval ~= 0 then
    Event(
      "CryptoKeyGenerateEvent",
      {
        actorProcess = CurrentProcessEntity,
        key = CryptoKeyEntity.fromHandle(context.p.phKey[0], context.p.dwFlags)
      }
    ):send(EventChannel.splunk)
  end
end

---@param context EntryExecutionContext
local CryptImportKey_onEntry = function(context)
end

---@param context ExitExecutionContext
local CryptImportKey_onExit = function(context)
  if context.retval ~= 0 then
    Event(
      "CryptoKeyImportEvent",
      {
        actorProcess = CurrentProcessEntity,
        key = CryptoKeyEntity.fromHandle(context.p.phKey[0], context.p.dwFlags)
      }
    ):send(EventChannel.splunk)
  end
end

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
      "CryptoKeyExportEvent",
      {
        actorProcess = CurrentProcessEntity,
        key = CryptoKeyEntity.fromHandle(context.p.hKey, CRYPT_EXPORTABLE)
      }
    ):send(EventChannel.splunk)
  end
end

Probe {
  name = "CryptoMonitorProbe",
  hooks = {
    {
      name = "CryptGenKeyHook",
      onEntry = CryptGenKey_onEntry,
      onExit = CryptGenKey_onExit
    },
    {
      name = "CryptImportKeyHook",
      onEntry = CryptImportKey_onEntry,
      onExit = CryptImportKey_onExit
    },
    {
      name = "CryptExportKeyHook",
      onEntry = CryptExportKey_onEntry,
      onExit = CryptExportKey_onExit
    }
  }
}
