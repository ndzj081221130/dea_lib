# UTF-8

require_relative "./comp_lifecycle_mgr"
module Dea
  
  class WaitingFreenessStrategy
    
    WAITING = "WAITING_FOR_FREENESS"
    attr_accessor :compLifecycleMgr
    
    def initialize(compLife)
      @compLifecycleMgr = compLife
      
    end
    
    def achieveFreeness(rootTxID,rootComp,parentComp,curTxID,hostComp)
      return nil
    end
    
    def isInterceptRequiredForFree(rootTx,compIdentifier,txCtx,isUpdateRCVD)
      return false
    end
    
    def isReadyForUpdate(hostComp)
      return @compLifecycleMgr.isReadyForUpdate()
    end
  end
  
end