setfenv(1, require "sysapi-ns")
local user = require "user.user"

local package = Package "UsersMonitorProbe"

ffi.load("samcli")

Case("UsersMonitorProbe") {
  case = function()
    package:load()

    local username = "test10"
    local password = "qwerty123"

    local ret = user.add(username, password)
    assert(ret == 0)

    ret = user.changePassword(username, password, "12345")
    assert(ret == 0)

    user.forEach(
      function(info)
        print(string.fromWC(info.usri0_name))
      end
    )

    ret = user.delete(username)
    assert(ret == 0)

    local events = fetchEvents("UserAddEvent")
    assert(#events ~= 0)
    events = fetchEvents("UserDeleteEvent")
    assert(#events ~= 0)
    events = fetchEvents("UserChangePasswordEvent")
    assert(#events ~= 0)
    events = fetchEvents("UsersEnumerationEvent")
    assert(#events ~= 0)

    package:unload()
  end
}
