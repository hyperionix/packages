setfenv(1, require "sysapi-ns")
local Crypto = require "crypto.Crypto"
local bor = bit.bor

local package = Package "Crypto Key Generated"

Case("mycase") {
  case = function()
    local crypto = Crypto.new()
    package:load()
    local key = crypto:Key(CALG_RSA_KEYX, CRYPT_EXPORTABLE)
    package:unload()

    local events = fetchEvents("Crypto Key Generated")
    assert(#events ~= 0)
  end
}
