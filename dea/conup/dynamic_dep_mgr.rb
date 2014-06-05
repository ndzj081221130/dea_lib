# coding: UTF-8
# conup-core
require "steno"
require "steno/core_ext"
require_relative "./dep_registry"
require_relative "./tx_lifecycle_mgr"
require_relative "./comp_lifecycle_mgr"
require_relative "./tx_context"
require_relative "./version_consistency"
require_relative "./comp_lifecycle_mgr"
require_relative "./node_mgr"
require_relative "./update_mgr"

module Dea
  class DynamicDepManager
    attr_accessor :algorithm # Algorithm
    attr_accessor :compLifecycleMgr
    attr_accessor :compObj #ComponentObject
    attr_accessor :inDepRegistry # DependenceRegistry
    attr_accessor :outDepRegistry # DependenceRegistry
    
    attr_accessor :scope #Scope
    
    attr_accessor :txLifecycleMgr
    
    
    def initialize(compObject) # we need a componentObject here
      @inDepRegistry = Dea::DependenceRegistry.new
      @outDepRegistry = Dea::DependenceRegistry.new
      @compObj = compObject 
      @algorithm = Dea::VersionConsistency.new
	    # @compLifecycleMgr = Dea::CompLifecycleManager.instance(@compObj)
      # @txLifecycleMgr = Dea::TxLifecycleManager.instance(identifier)
      #  这两个变量也不从这里获得，而是在nodeMgr.getDepManager时设置。
    end
     
    
    def dependenceChanged(hostComp) # String
      if @compObj.isTargetComp
        # TODO get UpdateManager and updateManager.checkFreeness
        puts "ddm dependenceChanged , call updateMgr.checkFreeness"
        updateManager = NodeManager.instance.getUpdateManager(hostComp)
        updateManager.checkFreeness(hostComp)
      else
        puts "ddm.dependenceChanged, #{hostComp} not target , cause not received update request "
      end
    end
    
    def dynamicUpdateIsDone
      puts "ddm: called dynamicUpdateIsDone"
      return algorithm.updateIsDone(@compObj.identifier, self)
    end
    
    def getAlgorithmOldVersionRootTxs
       return @algorithm.getOldVersionRootTxs(@inDepRegistry.dependences)  
    end
    
    def getRuntimeDeps
      return @outDepRegistry.dependences #set
    end
    
    def getRuntimeInDeps
      return @inDepRegistry.dependences
    end
    
    def getStaticDeps
      return @compObj.staticDeps # Set
    end
    
    def getStaticInDeps
      return @compObj.staticInDeps #Set
    end
    
    def getTxLifecycleMgr
      # return NodeManager...generate(TxLifecycleMgr)
      @txLifecycleMgr = Dea::NodeManager.instance.getTxLifecycleManager(@compObj.identifier)
       
      return @txLifecycleMgr
    end
    
    
    def getTxs
      return @txLifecycleMgr.getTxs()
    end
    
    def initLocalSubTx(txContext) #TransactionContext
	    puts "#{@compObj.identifier}.ddm: init sub compLifecycleMgr.nil?#{@compLifecycleMgr == nil}"
      return @algorithm.initLocalSubTx(txContext, @compLifecycleMgr ,self)
    end
    
    def isBlockRequiredForFree(algorithmOldVersionRootTxs ,txContext,isUpdateReqRCVD ) # Set<String> , TransactionContext,bool
      return @algorithm.isBlockRequiredForFree(algorithmOldVersionRootTxs,txContext,isUpdateReqRCVD,self)
    end
    
    def isReadyForUpdate
      
      return @algorithm.readyForUpdate(@compObj.identifier, self)
    end
    
    def manageDependencePayload(payload) #String
      puts "ddm : manageDependecePayload"
      plResolver = DepPayloadResolver.new(payload)
      
      operation = plResolver.operation
      puts "ddm operation = #{operation}"
      params = getParamFromPayload(plResolver)
      puts "ddm params #{params}"
      return @algorithm.manageDependence4(operation , params, self, @compLifecycleMgr)
    end
    # private method
    def manageDependence(txContext) #TransactionContext
      puts "#{@compObj.identifier}.ddm : in manageDepedence(txCtx) compLifecycleMgr.nil #{@compLifecycleMgr == nil }"
      @algorithm.manageDependence3(txContext, self, @compLifecycleMgr)
      return true
    end
    
    # this method is called by TxDepMonitor.notify
    def manageTx(txContext) # TransactionContext 
      curTxID = txContext.currentTx
      puts "#{@compObj.identifier}.ddm: in ManageTx  "
      #puts @txLifecycleMgr ==nil
      @txLifecycleMgr.updateTxContext(curTxID, txContext)
      
	    puts "#{@compObj.identifier}.ddm : txLifecycleMgr.txRegistry: #{@txLifecycleMgr.txRegistry}"
      return manageDependence(txContext)
    end
    
    def ondemandSetupIsDone
      
      inDep = ""
      @inDepRegistry.dependences.each{|dep|
           inDep += dep.to_s + ","
           
        }
      puts "#{@compObj.identifier}.ddm : inDep = #{inDep}"  
        
      outDep =""
      @outDepRegistry.dependences.each{|dep|
        outDep+= dep.to_s+ " ,"
        }  
      puts "#{@compObj.identifier}.ddm: outDep = #{outDep}"
      txs = getTxs()
      puts "#{@compObj.identifier}.ddm: ondemandSetupIsDone,Tx: #{txs}"  
      algorithm.initiate(@compObj.identifier , self)
      
    end
    
    def getParamFromPayload(depPayloadResolver ) #DepPayloadResolver
      
      params = {}# <String,String>
                                                                                                                                          
      params["srcComp"] = depPayloadResolver.getParameter(DepPayload::SRC_COMPONENT)
      params["targetComp"] = depPayloadResolver.getParameter(DepPayload::TARGET_COMPONENT)
      
      params["rootTx"] = depPayloadResolver.getParameter(DepPayload::ROOT_TX)
      
      params["parentTx"] = depPayloadResolver.getParameter(DepPayload::PARENT_TX)
      params["subTx"] = depPayloadResolver.getParameter(DepPayload::SUB_TX)
      
      return params
    end
    
    def notifySubTxStatus(subTxStatus, invocationCtx,componentLifecycleMgr, proxyRootTxId)
      # why!!! why not use invocationCtx!!!
      #                    TxEventType , InvocationContext, ComponentLifecycleMgr, String
      id = componentLifecycleMgr.compObj.identifier
      puts "#{id}.ddm调用notifySubTxStatus,then call algorithm.notifySubTxStatus"
      return @algorithm.notifySubTxStatus(subTxStatus, invocationCtx, componentLifecycleMgr , self,proxyRootTxId)          
    end
    
  end
  
end
