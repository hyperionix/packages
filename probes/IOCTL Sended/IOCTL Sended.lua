setfenv(1, require "sysapi-ns")
local ProcessEntity = hp.ProcessEntity
local EventChannel = hp.EventChannel
local ioctl = require"ioctl.ioctl"

---@param context EntryExecutionContext
local NtDeviceIoControlFile_onEntry = function(context)
end

---@param context ExitExecutionContext
local NtDeviceIoControlFile_onExit = function(context)
  if context.retval == STATUS_SUCCESS then
    local code = toaddress(context.p.IoControlCode)
    Event(
      "IOCTL Sended",
      {
        method = ioctl.getMethod(code),
        deviceType = ioctl.getDeviceType(code),
        func = ioctl.getFunction(code),
        inBufferSize = toaddress(context.p.InputBufferLength),
        outBufferSize = toaddress(context.p.OutputBufferLength),
        process = ProcessEntity.fromCurrent()
      }
    ):send(EventChannel.file, EventChannel.splunk)
  end
end

Probe {
  name = "IOCTL Sended",
  hooks = {
    {
      name = "NtDeviceIoControlFile",
      onEntry = NtDeviceIoControlFile_onEntry,
      onExit = NtDeviceIoControlFile_onExit
    }
  }
}
