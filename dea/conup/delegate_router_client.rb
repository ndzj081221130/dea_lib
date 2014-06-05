#UTF-8
# require ""
# require_relative "./node_mgr"
require_relative "../nats"

module Dea
  class DelegateRouterClient
    
    def DelegateRouterClient.notify_router(instance)
      raw_data = "{\"id\":\"b9bdc46ab4582344e17cc0fb9cb2fa33\",\"hosts\":[\"10.0.2.15\"]}"
      subject = "router.start"
      respond_to = nil
      message = Dea::Nats::Message.decode(instance.bootstrap.nats, subject, raw_data, respond_to)
      instance.bootstrap.handle_router_start(message)
      # "{\"id\":\"b9bdc46ab4582344e17cc0fb9cb2fa33\",\"hosts\":[\"10.0.2.15\"]},respond_to = 
    end
  end
end