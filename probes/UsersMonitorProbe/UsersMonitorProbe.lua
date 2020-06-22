setfenv(1, require "sysapi-ns")
local EventChannel = hp.EventChannel

local CurrentProcessEntity = hp.CurrentProcessEntity

local LOG_LEVEL = 0
local CONSOLE_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.console)
local DBG_LOG = hp.Logger:new(LOG_LEVEL, hp.Logger.sink.debug)
local LOG = DBG_LOG

local PRIV_LEVELS_NAMES = {
  [USER_PRIV_GUEST] = "Guest",
  [USER_PRIV_USER] = "User",
  [USER_PRIV_ADMIN] = "Administrator"
}

---@param context EntryExecutionContext
local NetUserAdd_onEntry = function(context)
end

---@param context ExitExecutionContext
local NetUserAdd_onExit = function(context)
  if context.retval == 0 then
    local info = ffi.cast("PUSER_INFO_1", context.p.buf)

    Event(
      "UserAddEvent",
      {
        actorProcess = CurrentProcessEntity,
        server = context.p.servername and string.fromWC(context.p.servername) or "local computer",
        user = string.fromWC(info.usri1_name),
        password = info.usri1_password and string.fromWC(info.usri1_password) or "",
        privileges = PRIV_LEVELS_NAMES[info.usri1_priv]
      }
    )
  end
end

---@param context EntryExecutionContext
local NetUserEnum_onEntry = function(context)
end

---@param context ExitExecutionContext
local NetUserEnum_onExit = function(context)
  if context.retval == 0 then
    -- TODO: add INFO_LEVEL to event?
    Event(
      "UsersEnumerationEvent",
      {
        actorProcess = CurrentProcessEntity,
        server = context.p.servername and string.fromWC(context.p.servername) or "local computer"
      }
    )
  end
end

---@param context EntryExecutionContext
local NetUserDel_onEntry = function(context)
end

---@param context ExitExecutionContext
local NetUserDel_onExit = function(context)
  if context.retval == 0 then
    Event(
      "UserDeleteEvent",
      {
        actorProcess = CurrentProcessEntity,
        server = context.p.servername and string.fromWC(context.p.servername) or "local computer",
        user = string.fromWC(context.p.username)
      }
    )
  end
end

---@param context EntryExecutionContext
local NetUserChangePassword_onEntry = function(context)
end

---@param context ExitExecutionContext
local NetUserChangePassword_onExit = function(context)
  if context.retval == 0 then
    Event(
      "UserChangePasswordEvent",
      {
        actorProcess = CurrentProcessEntity,
        server = context.p.domainname and string.fromWC(context.p.domainname) or "local computer",
        user = context.p.username and string.fromWC(context.p.username) or CurrentProcessEntity.user,
        oldPassword = string.fromWC(context.p.oldpassword),
        newPassword = string.fromWC(context.p.newpassword)
      }
    )
  end
end

Probe {
  name = "UsersMonitorProbe",
  hooks = {
    {
      name = "NetUserAddHook",
      onEntry = NetUserAdd_onEntry,
      onExit = NetUserAdd_onExit
    },
    {
      name = "NetUserEnumHook",
      onEntry = NetUserEnum_onEntry,
      onExit = NetUserEnum_onExit
    },
    {
      name = "NetUserDelHook",
      onEntry = NetUserDel_onEntry,
      onExit = NetUserDel_onExit
    },
    {
      name = "NetUserChangePasswordHook",
      onEntry = NetUserChangePassword_onEntry,
      onExit = NetUserChangePassword_onExit
    }
  }
}
