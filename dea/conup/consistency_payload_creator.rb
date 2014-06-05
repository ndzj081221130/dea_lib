# coding: UTF-8

require "steno"
require "steno/core_ext"
require_relative "./dep"
require_relative "./dep_payload"
module Dea
  class ConsistencyPayloadCreator
    
    def ConsistencyPayloadCreator.createPayload6(srcComp,targetComp,rootTx,
                                                      operation,parentTxID,subTxID)
      
      result = Dea::DepPayload::SRC_COMPONENT + ":" + srcComp+","+
               Dea::DepPayload::TARGET_COMPONENT + ":" + targetComp+","+
               Dea::DepPayload::ROOT_TX + ":" + rootTx + "," + 
               Dea::DepPayload::OPERATION_TYPE + ":" + operation + "," + 
               Dea::DepPayload::PARENT_TX + ":" + parentTxID +"," + 
               Dea::DepPayload::SUB_TX ;
                                                                  
      result                                                 
    end
    
    def ConsistencyPayloadCreator.createPayload4(srcComp,targetComp, rootTx,operation)
      result = Dea::DepPayload::SRC_COMPONENT + ":" + srcComp+","+
               Dea::DepPayload::TARGET_COMPONENT + ":" + targetComp+","+
               Dea::DepPayload::ROOT_TX + ":" + rootTx + "," + 
               Dea::DepPayload::OPERATION_TYPE + ":" + operation;
      result         
    end
    
    def ConsistencyPayloadCreator.createPayload5(srcComp,targetComp, rootTx,operation,scope)
      part = ConsistencyPayloadCreator.createPayload4(srcComp,targetComp,rootTx,operation);
      
      part += Dea::DepPayload::SCOPE + ":" + scope;
      
      part 
    end
    
    def ConsistencyPayloadCreator.createNormalRootTxEndPayload(scrComp,targetComp, rootTx,operation)
      return ConsistencyPayloadCreator.createPayload4(scrComp,targetComp, rootTx,operation)
    end
    
    def ConsistencyPayloadCreator.createRemoteUpDateIsDonePayload(srcComp,targetComp,operation)
      # puts "called"
      result = Dea::DepPayload::SRC_COMPONENT + ":" + srcComp+","+
               Dea::DepPayload::TARGET_COMPONENT + ":" + targetComp+","+                
               Dea::DepPayload::OPERATION_TYPE + ":" + operation
      # puts "creator: result = #{result}"
      return result
    end
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
  end
end