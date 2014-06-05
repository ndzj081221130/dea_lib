# UTF-8
require_relative "./msg_type"
require_relative "./update_operation_type"
require_relative "./update_context_payload_creator"
require_relative "./client"
require_relative "./client_sync"
require_relative "./comm_type"

module Dea
  class RemoteConf
    def sendMsg(ip,port,srcIdentifier,targetIdentifier,protocol,msgType,payload,commType)
      msg = {}
      msg["srcIdentifier"] = srcIdentifier
      msg["targetIdentifier"] = targetIdentifier
      msg["protocol"] = protocol
      msg["msgType"] = msgType
      msg["payload"] = payload
      msg["commType"] = commType
      Dea::ClientOnce.new(ip,port,msg.to_json)
    end
      
    def sendMsgSync(ip,port,srcIdentifier,targetIdentifier,protocol,msgType,payload,commType)
      msg = {}
      msg["srcIdentifier"] = srcIdentifier
      msg["targetIdentifier"] = targetIdentifier
      msg["protocol"] = protocol
      msg["msgType"] = msgType
      msg["payload"] = payload
      msg["commType"] = commType
      client = Dea::ClientSync.new(ip,port,msg.to_json)
      client
    end
    
    def update(ip,port,targetIdentifier,protocol,baseDir,classFilePath,contributionUri,compositeUri,scope)
      msgType = Dea::MsgType::REMOTE_CONF_MSG
      payload = Dea::UpdateContextPayloadCreator.createPayload(Dea::UpdateOperationType::UPDATE,
                                                              targetIdentifier,baseDir,classFilePath,
                                                              contributionUri,compositeUri,scope)
                                                              
       res = sendMsgSync(ip,port,nil,targetIdentifier,protocol,msgType,payload,Dea::CommType::SYN) 
       puts "res = #{res}"        
       return true                                               
    end
    
    def ondemand(ip,port,targetIdentifier,protocol,scope)
      msgType = Dea::MsgType::REMOTE_CONF_MSG
      payload = Dea::UpdateContextPayloadCreator.createPayload(Dea::UpdateOperationType::ONDEMAND,
                                                               targetIdentifier,scope)
      res = sendMsgSync(ip,port,nil,targetIdentifier,protocol,msgType,payload,Dea::CommType::SYN)
      puts "res = res"      
      return true                                                   
    end
    
    def isUpdated(ip,port,targetIdentifier,protocol)
      msgType = Dea::MsgType::REMOTE_CONF_MSG
      payload = Dea::UpdateContextPayloadCreator.createPayload(Dea::UpdateOperationType::GET_EXECUTION_RECORDER,
                                                                targetIdentifier)
      sendMsg(ip,port,nil,targetIdentifier,protocol,msgType,payload,Dea::CommType::ASYN)
      return true
    end
    
    def getExecutionRecorder(ip,port,targetIdentifier,protocol)
      msgType = Dea::MsgType::EXPERIMENT_MSG
      payload = Dea::UpdateContextPayloadCreator.createPayload(Dea::UpdateOperationType::GET_EXECUTION_RECORDER,targetIdentifier)
      
      return  sendMsg(ip,port,nil,targetIdentifier,protocol,msgType,payload,Dea::CommType::SYN)
    end
    
    def getUpdatedEndTime(ip,port,targetIdentifier,protocol)
      msgType = Dea::MsgType::EXPERIMENT_MSG
      payload = Dea::UpdateContextPayloadCreator.createPayload(Dea::UpdateOperationType::GET_UPDATE_ENDTIME,targetIdentifier)
      
      return  sendMsg(ip,port,nil,targetIdentifier,protocol,msgType,payload,Dea::CommType::SYN)
    end
    
    
  end
end