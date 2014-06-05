#UTF-8
require_relative "./node_mgr"
module Dea
  class ConcurrentVersionFreeness
    CONCURRENT_VERSION = "CONCURRENT_VERSION_FOR_FREENESS"
    
    attr_accessor :compLifecycleMgr
    
    def initialize(compLife)
      @compLifecycleMgr = compLife
      
    end
    
    def achieveFreeness(rootTxID,rootComp,parentComp,curTxID,hostComp)
      
      nodeMgr = Dea::NodeManager.instance
      compLifeMgr = nodeMgr.getCompLifecycleManager(hostComp)
      updateMgr = nodeMgr.getUpdateManager(hostComp)
      vaidToFreeMonitor = compLifeMgr.compObj.validToFreeSyncMonitor
      algorithmOldRootTxs = updateMgr.updateCtx.algorithmOldRootTxs
      
      validToFreeSyncMonitor.synchronize do
        if algorithmOldRootTxs != nil && algorithmOldRootTxs.include?(rootTxID) 
          
          puts "rootTxID #{rootTxID} is dispatched to old version"
          return updateMgr.updateCtx.oldVerClass
        else
          return updateMgr.updateCtx.newVerClass
        end
      end
    end
    
    def isInterceptRequiredForFree(rootTx,compIdentifier,txCtx,isUpdateRCVD)
      return false
    end
    
    def isReadyForUpdate(hostComp)
      updateMgr= NodeManager.instance.getUpdateManager(hostComp)
      
      oldVersionRootTxs = updateMgr.updateCtx.algorithmOldRootTxs
      puts "oldVersionRootTxs.size() = #{oldVersionRootTxs.size}"
      puts "oldVersionRootTxs:\n #{oldVersionRootTxs}"
      return @compLifecycleMgr.isReadyForUpdate() || oldVersionRootTxs.size() ==0 
    end
  end
end