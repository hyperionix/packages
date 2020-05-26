setfenv(1, require "sysapi-ns")

local Crypto = require "crypto.Crypto"
local crypto = Crypto.new()

local package = Package "Export Crypto Key"

Case("mycase") {
  case = function()
    package:load()
    local key = crypto:genKeyPair(CALG_RSA_KEYX)
    local k = crypto:exportKey(key, PRIVATEKEYBLOB)
    package:unload()
  end
}
