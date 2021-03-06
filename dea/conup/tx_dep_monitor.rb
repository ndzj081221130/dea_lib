# coding: UTF-8
# conup-extension
require "steno"
require "steno/core_ext"
require "set"
require_relative "./tx_dep_registry"
require_relative "./tx_lifecycle_mgr"
require_relative "./datamodel/tx_event_type"
require_relative "./datamodel/comp_status"
require_relative "./dynamic_dep_mgr"
require_relative "./update_mgr"
require_relative "./comp_lifecycle_mgr"
require_relative "./node_mgr"
module Dea
  class TxDepMonitor
    
    attr_accessor :txDepRegistry
    attr_accessor :serviceToComp #TODO here is a concurrentHashMap 这里我没用
    
    attr_accessor :txLifecycleMgr
    attr_accessor :compIdentifier #string
    attr_accessor :compObj
    
    
    def initialize(componentObject) # component is a componentObject
      @txDepRegistry = Dea::TxDepRegistry.new
      @compIdentifier = componentObject.identifier
      @compObj = componentObject
      key = @compIdentifier + ":" + componentObject.componentVersionPort.to_s
      @logger = @compObj.logger
      @txLifecycleMgr = Dea::NodeManager.instance.getTxLifecycleManager(key)
      @keyGet = key
    end
   
    def notify(et , curTxID , futureC , pastC) 
      # maybe collect_server will call this method or some other Mgr will call this
      # futureC is a set with Future components   
      #there are four TxEventType   
      
      
      #logger.info "TxDepMonitor.notify #{et} , #{curTxID}"
      
      txContext = @txLifecycleMgr.getTransactionContext(curTxID)
      rootTx = ""
      if txContext == nil #  testing: added by zhangjie
        rootTx = @txLifecycleMgr.createID(curTxID) #如果txid对应的txContext是空的，则调用createID
        txContext = @txLifecycleMgr.getTransactionContext(curTxID)
      else
        rootTx = txContext.rootTx
      end
      # check txContext!=nil
      #   testing get a ondemandMonitor and 修改eventType
      
      key = @compObj.identifier + ":" + @compObj.componentVersionPort.to_s
      compLifecycleMgr = Dea::NodeManager.instance.getCompLifecycleManager(@keyGet)
      ondemandMonitor = @compObj.ondemandSyncMonitor
      
      ondemandMonitor.synchronize do
        txContext.eventType = et
      end
       
      
      txDep = TxDep.new(futureC , pastC)
      
      @txDepRegistry.addLocalDep(curTxID,txDep)
       
      dynamicDepMgr = Dea::NodeManager.instance.getDynamicDepManager(@keyGet)
                 
      result = dynamicDepMgr.manageTx(txContext)
      @logger.debug "#{@keyGet}.tx_dep_monitor: ddm.manageTx result = #{result}"
      if(et == Dea::TxEventType::TransactionEnd) #如果是事务结束，则删除TxCtx和local边
        
        @logger.debug "#{@keyGet}.tx_dep_monitor: handle TxEnd"
        @txLifecycleMgr.removeTransactionContext(curTxID)
        @txDepRegistry.removeLocalDep(curTxID)
        
        ## testing : call update manager attempToUpdate  
        
        updateMgr = Dea::NodeManager.instance.getUpdateManager(key)
        
        if compLifecycleMgr.compStatus == Dea::CompStatus::VALID && updateMgr.isDynamicUpdateRqstRCVD()
          @logger.debug "#{@keyGet}.tx_dep_monitor: call updateMgr.attemptToUpdate"
          updateMgr.attemptToUpdate()
        else
          @logger.debug "#{@keyGet}.tx_dep_monitor: 不能调用attemptToUpdate, status = #{compLifecycleMgr.compStatus}, rqstRCVD = #{updateMgr.isDynamicUpdateRqstRCVD}"
          
        end
      end
        
        return rootTx
      # result  
    end
    
    def isLastUse(txId, targetCompIdentifier, hostComp  ) #String,String,String
      #fservices = lddm.getFuture() #TODO need testing
       @logger.debug "#{@keyGet}.txDepMonitor.isLastUse : targetComp = #{targetCompIdentifier}, host = #{hostComp}"
      # get isLastUse from app? or what??
    #  tmpFutureServices = Set.new(fservices)
     #  tmpFutureServices.each{|fs|
      #  if fs != convertServiceToComponents(fs,hostComp)
       #   tmpFutureServices.delete fs
        #end
         #}
      
      isLastUse = true
      
      txDep = @txDepRegistry.getLocalDep(txId)
      if txDep != nil
        futureComps = txDep.futureComponents
        
        if futureComps.size < 1
          return false
        end
      else
        @logger.debug "#{@keyGet}.txDepMonitor.isLastUse, txDep nil"
      end
      #tmpFutureServices.each{|fs|
        
       # if whetherUseInFuture(fs)#(lddm.whetherUseInFuture(fs))
         # return false
        #end
        #}
      return isLastUse
    end
    #  how should I handle lddm??? 这个用消息来传递啊，
    #原来的java代码是通过查询lddm获得的，这里我们当接受到的消息写Future集合为空时，返回false
   
    
    
     
    # but my Future and Past Components is sent by clients ,
    # #so needn't these two methods
    def convertServicesToComponents(services,hostComp) # Set<string>,String
      #TODO应该用不到
      res = Set.new
      services.each{|service|
          set << Dea::TxDepMonitor.convertServiceToComponent(service,hostComp)
        }
    end
    
    def TxDepMonitor.convertServiceToComponent(service,hostComp) #String,String
      #  get DomainRegistry , Endpoints to cal serviceToComp
      

      parts = service.split(/./)
      if parts.size >= 1
        last = parts[parts.size-1]
        return last+"Component"
      else
        return nil
      end
    
    end
    
    
  end
end
