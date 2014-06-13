# coding: UTF-8

require "steno"
require "steno/core_ext"
require "securerandom"
require "set"
require 'minitest/autorun'
require_relative "./tx_context"
require_relative "./component"
require_relative "./tx_registry"
require_relative "./comp_lifecycle_mgr"
require_relative "./tx_dep_monitor"
require_relative "./tx_event_type"
require_relative "./tx_dep"
require_relative "./dynamic_dep_mgr"
require_relative "./update_mgr"
require_relative "./node_mgr"
module Dea
  
  class TxLifecycleManager
    # one dea has only one txLifecycleMgr, so  it is a singleton
    attr_accessor :txRegistry # TxRegistry <tid, TxContext>
    attr_accessor :compObject
    attr_accessor :InvocationContexts #  shift remove first ele,真传的是Invocation啊！
    attr_accessor :cachedTxContexts
    
    attr_accessor :curCachedInvocationContext #这个信息，即维护来自父亲的调用信息，也维护自己将对sub的调用信息 
    attr_accessor :curCachedTxContext#这个是记录该构件是被其他构件调用的，还是直接被用户调用的
    
    attr_accessor :tx_invocation_hash
    
    include MiniTest
    
    def notifyCache(invocationContext)
      
      puts "notified to cahce #{invocationContext}"
      @InvocationContexts << invocationContext
      
    end
    
    
     def initialize(comp) # comp is ComponentObject
      @compObject = comp
      @txRegistry = Dea::TransactionRegistry.new
      @InvocationContexts = Array.new
      @curCachedInvocationContext = nil
      @curCachedTxContext = nil
      @cachedTxContexts = Array.new
      @tx_invocation_hash = {}
    end
    
     
    
    def createID(id) # rather , register id!!! called when ???
      #  here,there are two kinds of txContext
      # 1 has no parent/root
      # 2 has parent/root 
      
      #generate an id?
     # id = "fdfad-4525-fgsg-5644"
     # java used InterceptorCache to share root/parent and tx/comp information between different interceptors
     # if InterceptorCache.getInstace(compObj).getTxCtx(getThreadID())!=null
     # then txContext = InterceptorCache.getInstace(compObj).getTxCtx(getThreadID() )
     #else we new a txContext and add <getThreadID(), txContext > to InterceptorCache
      txContext = Dea::TxContext.new
      txContextCalViaCache = Dea::TxContext.new
      puts "what?#{@InvocationContexts}"
      if @InvocationContexts.size < 1
        
        puts "tx_lifecycle_mgr: no cache context，当前事务是根事务"
        txContext.currentTx= id
        txContext.parentTx = id
        txContext.rootTx = id
        
        txContext.hostComponent=@compObject.identifier 
        txContext.parentComponent= @compObject.identifier
        txContext.rootComponent= @compObject.identifier   
        
        txContextCalViaCache.currentTx= id
        txContextCalViaCache.parentTx = id
        txContextCalViaCache.rootTx = id
        
        txContextCalViaCache.hostComponent=@compObject.identifier 
        txContextCalViaCache.parentComponent= @compObject.identifier
        txContextCalViaCache.rootComponent= @compObject.identifier   
        puts "txLifecycleMgr: 当前事务时根事务，也存储txContext"
        @curCachedTxContext = txContextCalViaCache #如果没有人调用call，那么有cache？
      # invocationSequence should not be null
      #txContext.invocationSequence = ??? we don't need this
      else
        puts "#{@compObject.identifier}.tx_life_mgr : cache not nil，当前事务是子事务 "
        puts @InvocationContexts
        puts "--- ---- ---------- to be deleted --- --- --- --- "
        
        invocationContext = @InvocationContexts.shift
        
        # puts "change before ? invocationCtx = #{@tx_invocation_hash[id]} "
        @tx_invocation_hash[id] = invocationContext
        
        # @curCachedInvocationContext = invocationContext #从调用关系中，获取信息。那么，通过这个？
        # puts "cachedInvocationCtx: #{@curCachedInvocationContext}"
#        
        # @curCachedInvocationContext.subTx = id 
        # @curCachedInvocationContext.subComp = @compObject.identifier
        
        # puts "change after invocationCtx = #{@tx_invocation_hash[id]} "
        
        txContext.currentTx=id
        txContext.parentTx = invocationContext.parentTx # invocationParent = it self
        txContext.rootTx= invocationContext.rootTx
        
        txContext.hostComponent=@compObject.identifier
        txContext.parentComponent= invocationContext.parentComp
        txContext.rootComponent= invocationContext.rootComp
        puts "--------------------to be ended -----------------"
        
        
        initLocalSubTx(@compObject.identifier,invocationContext.subTx,txContext)
#         先不删除上面的代码，同时计算通过txCache，看结果是不是一样的
        txContextInCache = @cachedTxContexts.shift
        
        rootTx = txContextInCache.rootTx
        parentTx = txContextInCache.parentTx
        
        currentTx = txContextInCache.currentTx
        hostComponent = txContextInCache.hostComponent
        rootComponent = txContextInCache.rootComponent
        parentComponent = txContextInCache.parentComponent
        invocationSequence = txContextInCache.invocationSequence
        
        @curCachedTxContext = txContextInCache         
        if rootTx == nil && parentTx == nil && currentTx == nil && hostComponent != nil
          # 当前tx时根事务
          
          currentTx = id
          rootTx = currentTx  
          parentTx = currentTx
        
          
          
          
          @curCachedTxContext.currentTx = currentTx
          @curCachedTxContext.parentTx = parentTx
          @curCachedTxContext.rootTx  = rootTx
          
          rootComponent = hostComponent
          parentComponent = hostComponent
          
          @curCachedTxContext.rootComponent = hostComponent
          @curCachedTxContext.hostComponent = hostComponent
          @curCachedTxContext.parentComponent = parentComponent
          
          puts "cached root tx id = #{rootTx}"
        elsif rootTx != nil && parentTx != nil && hostComponent != nil
          
          #当前事务是子事务
          
          currentTx = id
          
          @curCachedTxContext.currentTx = currentTx
          
        else
          puts "dirty data"
        end
        
        
        txContext2 = TxContext.new
        
        txContext2.currentTx=currentTx
        txContext2.hostComponent=hostComponent
        txContext2.parentComponent=parentComponent
        txContext2.rootComponent=rootComponent
        
        txContext2.parentTx= parentTx
        
        txContext2.rootTx= rootTx
        
        txContext2.invocationSequence=invocationSequence
        
        puts "tx2 = #{txContext2}"
        

      end
      puts "#{@compObject.identifier}.createID #{txContext}"
      puts "-----------createID finished -------------"
      @txRegistry.addTransactionContext(id,txContext)
      # @curTxContext = txContext
      
      return txContext.rootTx
    end
    
    def createFakeTxId # if our tx id is generated by 
       # uuid = UUID.new
       # return uuid.generate
       txID = SecureRandom.uuid
       return "FAKE_TX_ID"+txID.to_s 
    end
    
    def destroyID(id)
      @txRegistry.removeTransactionContext(id)
    end
    
    def getCompIdentifier
      return @compObject.identifier
    end
    
    def getTransactionContext(curTxID)
      return @txRegistry.getTransactionContext(curTxID)
    end
    
    def getTxs
      return @txRegistry.getTransactionContexts()
    end
    #called by who ??? 显然时被txDepMonitor调用啊
    def rootTxEnd(hostComp,port, rootid) #TODO need testing
      key  = hostComp + ":" + port.to_s
       puts "tx_lifecycle_mgr.rootTxEnd: hostComp = #{hostComp} , port = #{port}"
       compObject = Dea::NodeManager.instance.getComponentObject(key)
       compLifecycleMgr = Dea::NodeManager.instance.getCompLifecycleManager(key)
       # puts "tx_lifecycle_mgr: compLifecycleMgr.nil? #{compLifecycleMgr == nil}"
       updateMgr = Dea::NodeManager.instance.getUpdateManager(key)
       #   get update manager
       validToFreeSyncMonitor = compLifecycleMgr.compObj.validToFreeSyncMonitor
       puts "tx_lifecycle_mgr: txID= #{rootid} , hostComp: #{hostComp}, compStatus: #{compLifecycleMgr.compStatus}"
       puts "tx_life_cycle_mgr before valid.sync"
       validToFreeSyncMonitor.synchronize do
         #  testing
         puts "tx_lifecycle_mgr.rootTxEnd: call updateMgr.removeAlgorithmOldRootTx"
         updateMgr.removeAlgorithmOldRootTx(rootid)
       end
       
       puts "in txLifecycleMgr.rootTxEnd after valid.sync"
    end
    
    # TODO testing：：：needed to be considered ??? 这个反正代码我写了，但是暂时还没有测试到，
        # what this mean ???
        # who called this method???原来是在bufferInterceptor中调用的
        # this is called by buffer interceptor
        # fake Tx ID is used to solve these kind of problems
        # an method call has already passed buffer intercepor , but not finishing its calling Auth Comp
        # while Auth is updated , there will be problems!!!
        # I have not write my buffer interceptor in gorouter,so it is to be done 
        # 或者拦截器写在collect_server和router中，router负责拦截真正的将转发给tuscany的请求
        # 但是collect_server拦截上面的那个情况，如果调用hello请求已经经过router，也就是说，该请求一定会被处理了。
        # collect_server其实时无能为力的。
        
        # 那collect_server还需要拦截请求么？？？
        
         
    def initLocalSubTx(hostComp,fakeSubTx, txContextCache) # String , String , TransactionContext txCtxInCache
        puts "txLifecycleMgr.initLocalSubTx , fakeSubTx = #{fakeSubTx}"
        puts "#{@compObject.identifier}.tx_lifecycle_mgr : initLocalSubTx"
        key = @compObject.identifier + ":" + @compObject.componentVersionPort.to_s
        depMgr = Dea::NodeManager.instance.getDynamicDepManager(key)
         	 
        txDepMonitor = Dea::NodeManager.instance.getTxDepMonitor(key)
        
        txDepRegistry = txDepMonitor.txDepRegistry
                
        parentComp = txContextCache.parentComponent
        parentTx = txContextCache.parentTx
        rootTx = txContextCache.rootTx
        rootComp = txContextCache.rootComponent
        
        txContext = Dea::TxContext.new
        
        txContext.isFakeTx=true
        
        txContext.currentTx=fakeSubTx
        txContext.hostComponent= hostComp
        
	      puts "#{@compObject.identifier}.tx_lifecycle mgr: initSub host.nil? #{txContext.hostComponent == nil     }"
        txContext.eventType=TxEventType::TransactionStart
        
        txDep = Dea::TxDep.new(Set.new, Set.new)
        
        txDepRegistry.addLocalDep(fakeSubTx,txDep)
        
        txContext.parentComponent=parentComp
        txContext.parentTx=parentTx
        
        txContext.rootTx=rootTx
        txContext.rootComponent= rootComp
        
        puts "before add fake , txRegistry = #{@txRegistry}"
        @txRegistry.addTransactionContext(fakeSubTx,txContext)
        puts "after add fake, txRegistry = #{@txRegistry}"
        
        puts "tx_lifecycle_mgr调用ddm.initLocalSubTx之前"
        return depMgr.initLocalSubTx(txContext)
        
    end
    
    
    def endLocalSubTx(hostComp, fakeSubTx) # String ,string   testing
        puts "#{hostComp}.tx_lifecycle_mgr: endLocalSubTx"
        #这个要在
        #notify(depMonitor)前做，否则TxEnd，直接将tx都删了.应该不是这个问题，因为存储的应该是一个fakeTx
        
        #这个方法是在traceInterceptor中调用的，在reference阶段，经过txInterceptor和bufferInterceptor之后，
        # 如果是service端，如果是子事务，调用endocalSubTx；如果是reference端，调用endRemoteSubTx
        key = @compObject.identifier + ":" + @compObject.componentVersionPort.to_s 
        depMgr = Dea::NodeManager.instance.getDynamicDepManager(key)
        
        compLifecycleMgr = Dea::NodeManager.instance.getCompLifecycleManager(key)
      
        txDepMonitor = Dea::NodeManager.instance.getTxDepMonitor(key)
      
        txDepRegistry = txDepMonitor.txDepRegistry
      
        proxyRootTxId = nil
        
        ondemandMonitor = @compObject.ondemandSyncMonitor
        
        ondemandMonitor.synchronize do
          puts "#{hostComp}.fakeSubTx = #{fakeSubTx}"
          fakeSubTxCtx = depMgr.getTxs()[fakeSubTx]
          puts "#{hostComp}.depMgr.getTxs(): \n \t #{depMgr.getTxs()}\n"
          puts "#{hostComp}.fakeSubTxCtx = #{fakeSubTxCtx}"
          if fakeSubTxCtx
            proxyRootTxId = fakeSubTxCtx.getProxyRootTxId(depMgr.scope)
            #这个计算的是call的rootTx
          end
            puts "before delete #{fakeSubTx}"
            puts depMgr.getTxs()
            depMgr.getTxs().delete(fakeSubTx)
            puts "after delete #{fakeSubTx}"
            puts depMgr.getTxs()
            
            puts "before removeLocalDep \n\t txDepRegistry = #{txDepRegistry}"
            res = txDepRegistry.removeLocalDep(fakeSubTx) # removeLocal
            
            puts "removeLocalDep res = #{res}"
        end
        puts "txLifecycleMgr: endLocalSubTx.proxyRootTxId #{proxyRootTxId}"
        proxyRootTxId
    end
    
    def resolveInvocationContext(invocationContext, hostComp)
      #这个是在service端被调用的
      # if @curInvocationContext == nil
        # generate and init TransactionDependecy
        
        #如果cache.getTxCtx(ThreadID) == nil, 会向cache中存入一个txContex
        #这里其实维护的时txContext和InvocationContext的转换，在dea里，我们不区分这个两个东西
        
        #这里从InvocationContext，解析出TxContext并且缓存到队列
        
        txContext = TxContext.new()
        txContext.currentTx= nil #创建一个TxContext，并缓存
        txContext.parentTx= invocationContext.parentTx
        txContext.parentComponent= invocationContext.parentComp
        txContext.rootTx= invocationContext.rootTx
        txContext.rootComponent= invocationContext.rootComp
        
        
        txContext.hostComponent= hostComp
        
        @cachedTxContexts << txContext
        
    end
    
    def createInvocation(hostComp, serviceName, txDepMonitor)
      # 这个方法在reference端被调用，txInterceptor在traceReference时，调用该方法， 在消息头插入invocationCtx
      # 也就是call在通知hello时，在msg中加入这个
      
      #虽然rgc说这个时计算scope的，但是还是加入吧，因为在service端，会根据resolve出来的invocatonCtx，调用startRemoteSubTx
      
      invocationCtx = nil
      if @curCachedTxContext   == nil #invoked  tx是根事务@curCachedTxContext
        puts #"当前invocationCtx == nil,现在应该不会出现这个情况，因为无论如何，我都在createID的时候，将curCachedTxContext赋值了"
        para = ""
        invocationCtx = InvocationContext.new(para,para,para,para,para,para,para)
      else
         
        puts "cachedTx = #@curCachedTxContext"
        rootTx = @curCachedTxContext.rootTx 
        #这里的root，是cached.root, 如果请求是来自papa的，那么root = papa.root
        rootComp = @curCachedTxContext.rootComponent 
        
        currentTx = @curCachedTxContext.currentTx
        parentTx = currentTx
        
        parentComp = hostComp
        
       
        subTx = createFakeTxId()#创建一个fake id
        puts "createInvocation. fakeSubTx = #{subTx}"
        subComp = serviceName
        
        invokeSequence = "" + hostComp + ":" + currentTx
        #因为这个invocationCtx是要发给sub的
        invocationCtx = InvocationContext.new(rootTx,rootComp,parentTx,parentComp,subTx,subComp,invokeSequence)  
        puts "tx_life_mgr: start remote sub tx :   here，subTx is fakeTx \n \t invocationCtx = #{invocationCtx}"
        startRemoteSubTx(invocationCtx)
         
      end
      
      return invocationCtx
    end
    
    def startRemoteSubTx(invocationCtx) 
      # 在vc中，notifyStartRemoteSubTx方法被deprecated
      # 还是应该通知papa，startRemoteSubTx
      puts "tx_lifecycle_mgr: startRemoteSubTx"
      #  need testing ， 这个方法只在createInvocation方法中被调用了
      hostComp = invocationCtx.parentComp # this not equals to current Component???
      
      #assert_equal(hostComp,@compObject.identifier)
      #TODO testing 
      if hostComp == @compObject.identifier
        puts "hostComp = identifier"
      else
        puts "!!!error , in start RemoteSubTx"
        
        
      end
      
      
      key = @compObject.identifier + ":" + @compObject.componentVersionPort.to_s
      
      ddm = Dea::NodeManager.instance.getDynamicDepManager(key)
       
       
      compLifecycleMgr = Dea::NodeManager.instance.getCompLifecycleManager(key)
      
      ddm.notifySubTxStatus(Dea::TxEventType::TransactionStart,invocationCtx,compLifecycleMgr,nil)
      
    end
    
    def endRemoteSubTx(invocationCtx , proxyRootTxId) # InvocationContext, String
      
      hostComp = invocationCtx.parentComp
#         need testing
      #assert_equal(hostComp,@compObject.identifier)
      if hostComp == @compObject.identifier
        puts "equal"
      else
        puts "!!!error!! in endRemoteSubTx"
      end
      key = @compObject.identifier + ":" + @compObject.componentVersionPort.to_s
      
      puts "#{hostComp}.tx_lifecycle_mgr: endRemoteSubTx , key = #{key}" # 但是这个方法在traceInterceptor中被调用了
      depMgr = Dea::NodeManager.instance.getDynamicDepManager(key)
      compLifecycleMgr = Dea::NodeManager.instance.getCompLifecycleManager(key)
      
      return depMgr.notifySubTxStatus(TxEventType::TransactionEnd,invocationCtx,compLifecycleMgr,proxyRootTxId)
    end
    
    def updateTxContext(currentTxID, txContext) # string , TransactionContext
      if ! @txRegistry.contains(currentTxID)
        @txRegistry.addTransactionContext(currentTxID , txContext)
      else
        @txRegistry.updateTransactionContext(currentTxID , txContext)
      end
      
    end
    
    def getTransactionContext(curTxID)
      return @txRegistry.getTransactionContext(curTxID)
    end
    
    def removeTransactionContext(curTxID)
      @txRegistry.removeTransactionContext(curTxID)
    end
    
   
    
    
    
    
  end
end
