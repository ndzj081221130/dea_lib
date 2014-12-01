# coding: UTF-8
# conup-core
require "steno"
require "steno/core_ext"
gem "minitest"
require 'minitest/autorun'

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
    
    attr_accessor :logger
    attr_accessor :keyGet
    def initialize(compObject) # we need a componentObject here
      @inDepRegistry = Dea::DependenceRegistry.new
      @outDepRegistry = Dea::DependenceRegistry.new
      @compObj = compObject 
      @algorithm = Dea::VersionConsistency.new
      @logger = compObject.logger
      @keyGet = @compObj.identifier + ":" + @compObj.componentVersionPort.to_s
       
	    # @compLifecycleMgr = Dea::CompLifecycleManager.instance(@compObj)
      # @txLifecycleMgr = Dea::TxLifecycleManager.instance(identifier)
      #  这两个变量也不从这里获得，而是在nodeMgr.getDepManager时设置。
    end
     
    
    def dependenceChanged(hostComp) # String
      
      #assert_equal(hostComp,@compObj.identifier)
      
      if hostComp== @compObj.identifier
        @logger.debug "#{@keyGet}.ddm in dependenceChanged, equal !"
      else
        @logger.debug "#{@keyGet}.ddm !!!error not equal"
      end
      if @compObj.isTargetComp
        # TODO get UpdateManager and updateManager.checkFreeness
        @logger.debug "#{@keyGet}.ddm dependenceChanged , call updateMgr.checkFreeness"
        updateManager = NodeManager.instance.getUpdateManager(@keyGet)
        updateManager.checkFreeness(@keyGet)
      else
        @logger.debug "#{@keyGet}.ddm.dependenceChanged, #{@keyGet} not target , cause not received update request "
      end
    end
    
    def dynamicUpdateIsDone
      @logger.debug "#{@keyGet}.ddm: called dynamicUpdateIsDone"
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
      @txLifecycleMgr = Dea::NodeManager.instance.getTxLifecycleManager(@keyGet)
       
      return @txLifecycleMgr
    end
    
    
    def getTxs
      return @txLifecycleMgr.getTxs()
    end
    
    def initLocalSubTx(txContext) #TransactionContext
	    @logger.debug "#{@keyGet}.ddm: init sub compLifecycleMgr.nil?#{@compLifecycleMgr == nil}"
      return @algorithm.initLocalSubTx(txContext, @compLifecycleMgr ,self)
    end
    
    def isBlockRequiredForFree(algorithmOldVersionRootTxs ,txContext,isUpdateReqRCVD ) # Set<String> , TransactionContext,bool
      return @algorithm.isBlockRequiredForFree(algorithmOldVersionRootTxs,txContext,isUpdateReqRCVD,self)
    end
    
    def isReadyForUpdate
      
      return @algorithm.readyForUpdate(@compObj.identifier, self)
    end
    
    def manageDependencePayload(payload) #String
      @logger.debug "#{@keyGet}.ddm : manageDependecePayload"
      plResolver = DepPayloadResolver.new(payload)
      
      operation = plResolver.operation
      @logger.debug "#{@keyGet}.ddm operation = #{operation}"
      params = getParamFromPayload(plResolver)
      @logger.debug "#{@keyGet}.ddm params #{params}"
      return @algorithm.manageDependence4(operation , params, self, @compLifecycleMgr)
    end
    # private method
    def manageDependence(txContext) #TransactionContext
      @logger.debug "#{@keyGet}.ddm : in manageDepedence(txCtx) compLifecycleMgr.nil #{@compLifecycleMgr == nil }"
      @algorithm.manageDependence3(txContext, self, @compLifecycleMgr)
      return true
    end
    
    # this method is called by TxDepMonitor.notify
    def manageTx(txContext) # TransactionContext 
      curTxID = txContext.currentTx
      @logger.debug "#{@keyGet}.ddm: in ManageTx  "
       
      @txLifecycleMgr.updateTxContext(curTxID, txContext)
      
	    @logger.debug "#{@keyGet}.ddm : txLifecycleMgr.txRegistry: #{@txLifecycleMgr.txRegistry}"
      return manageDependence(txContext)
    end
    
    def ondemandSetupIsDone
      
      inDep = ""
      @inDepRegistry.dependences.each{|dep|
           inDep += dep.to_s + ","
           
        }
      @logger.debug "#{@keyGet}.ddm : inDep = #{inDep}"  
        
      outDep =""
      @outDepRegistry.dependences.each{|dep|
        outDep+= dep.to_s+ " ,"
        }  
      @logger.debug "#{@keyGet}.ddm: outDep = #{outDep}"
      txs = getTxs()
      @logger.debug "#{@keyGet}.ddm: ondemandSetupIsDone,Tx: #{txs}"  
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
      @logger.debug "#{@keyGet}.ddm调用notifySubTxStatus,then call algorithm.notifySubTxStatus"
      return @algorithm.notifySubTxStatus(subTxStatus, invocationCtx, componentLifecycleMgr , self,proxyRootTxId)          
    end
    
  end
  
end
