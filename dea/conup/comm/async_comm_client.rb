# UTF-8

require_relative "./client_once"
 
module Dea
  
  class ASynCommClient
    def ASynCommClient.sendMsg(ip,port,srcIdentifier,targetIdentifier,protocol,msgType,payload,commType)
      msg = {}
      msg["srcIdentifier"] = srcIdentifier
      msg["targetIdentifier"] = targetIdentifier
      msg["protocol"] = protocol
      msg["msgType"] = msgType
      msg["payload"] = payload
      msg["commType"] = commType
      Dea::ClientOnce.new(ip,port,msg.to_json)
    end
  end
end
