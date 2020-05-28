setfenv(1, require "sysapi-ns")
local Crypto = require "crypto.Crypto"
local bor = bit.bor

local package = Package "Crypto Key Exported"

Case("mycase") {
  case = function()
    local crypto = Crypto.new()
    package:load()
    local key = crypto:Key(CALG_RSA_KEYX, CRYPT_EXPORTABLE)
    key:export(PRIVATEKEYBLOB)
    package:unload()

    local events = fetchEvents("Crypto Key Exported")
    assert(#events ~= 0)
  end
}
