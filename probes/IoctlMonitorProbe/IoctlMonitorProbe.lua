setfenv(1, require "sysapi-ns")
local ioctl = require "ioctl.ioctl"
local CurrentProcessEntity = hp.CurrentProcessEntity
local EventChannel = hp.EventChannel

---@param context EntryExecutionContext
local NtDeviceIoControlFile_onEntry = function(context)
end

---@param context ExitExecutionContext
local NtDeviceIoControlFile_onExit = function(context)
  if context.retval == STATUS_SUCCESS then
    local code = toaddress(context.p.IoControlCode)
    Event(
      "IoctlSendEvent",
      {
        method = ioctl.getMethod(code),
        deviceType = ioctl.getDeviceType(code),
        func = ioctl.getFunction(code),
        inBufferSize = toaddress(context.p.InputBufferLength),
        outBufferSize = toaddress(context.p.OutputBufferLength),
        actorProcess = CurrentProcessEntity
      }
    ):send(EventChannel.file, EventChannel.splunk)
  end
end

Probe {
  name = "IoctlMonitorProbe",
  hooks = {
    {
      name = "NtDeviceIoControlFileHook",
      onEntry = NtDeviceIoControlFile_onEntry,
      onExit = NtDeviceIoControlFile_onExit
    }
  }
}
