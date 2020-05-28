setfenv(1, require "sysapi-ns")
local Crypto = require "crypto.Crypto"
local bor = bit.bor

local package = Package "Crypto Key Imported"

Case("mycase") {
  case = function()
    local crypto = Crypto.new()
    package:load()
    local key = crypto:Key(CALG_RSA_KEYX, CRYPT_EXPORTABLE)
    local blob = key:export(PRIVATEKEYBLOB)
    crypto:KeyImport(blob)
    package:unload()

    local events = fetchEvents("Crypto Key Imported")
    assert(#events ~= 0)
  end
}
