local EventChannel = hp.EventChannel

Esm {
  name = "SendAllToFileEsm",
  states = {
    {
      name = "initial",
      triggers = {
        {
          eventName = "^%a+",
          action = function(state, event)
            event:send(EventChannel.file)
          end
        }
      }
    }
  }
}
