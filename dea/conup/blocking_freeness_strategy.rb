# UTF-8
require_relative "./comp_lifecycle_mgr"
require_relative "./node_mgr"
module Dea
  class BlockingFreenessStrategy
    # def initialize()
    
    BLOCKING = "BLOCKING_FOR_FREENESS"
    attr_accessor :compLifecycleMgr
    
    def initialize(compLife)
      @compLifecycleMgr = compLife
      puts "blocking: new"
    end
    
    def achieveFreeness(rootTxID,rootComp,parentComp,curTxID,hostComp)
      return nil
    end
    
    def getFreenessType()
      Dea::BlockingFreenessStrategy::BLOCKING
    end
    
    def isInterceptRequiredForFree(rootTx,compIdentifier,txCtx,isUpdateRCVD)
      puts "blocking. isInterceptRequiredForFree"
      node = Dea::NodeManager.instance
      depMgr = node.getDynamicDepManager(compIdentifier)
      updateMgr = node.getUpdateManager(compIdentifier)
      puts "blocking: isInterceptRequireForFree method"
      algorithmOldVersionRootTxs = nil
      if isUpdateRCVD
        algorithmOldVersionRootTxs = updateMgr.updateCtx.algorithmOldRootTxs
      else
        algorithmOldVersionRootTxs = nil
      end
      
      
      return depMgr.isBlockedRequiredForFree(algorithmOldVersionRootTxs,txCtx,isUpdateRCVD)
    end
    
    def isReadyForUpdate(hostComp)
      return @compLifecycleMgr.isReadyForUpdate()
    end
    
    
  end
end