local EventChannel = hp.EventChannel

Esm {
  name = "SendAllToSplunkEsm",
  states = {
    {
      name = "initial",
      triggers = {
        {
          eventName = "^%a+",
          action = function(state, event)
            event:send(EventChannel.splunk)
          end
        }
      }
    }
  }
}
