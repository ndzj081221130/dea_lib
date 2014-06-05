# coding: UTF-8
# conup-core
 require  "steno"
 require  "steno/core_ext"
 require  "set"

 require_relative "./tx_context"
 require_relative "./tx_event_type"
 require_relative "./dynamic_dep_mgr"
 require_relative "./comp_lifecycle_mgr"
 require_relative "./comp_status"
 require_relative "./dep"
 require_relative "./dep_registry"
 require_relative "./consistency_payload_creator"
 require_relative "./xml_util"
module Dea
  class VersionConsistency
    
    FUTURE_DEP="FUTURE_DEP"
    PAST_DEP="PAST_DEP"
    ALGORITHM_TYPE="CONSISTENCY_ALGORITHE"
    
    attr_accessor :isSetupDone #ConcurrentHashMap   <String ,boolean>
    attr_accessor :xmlUtil
    
    def initialize
      @xmlUtil = Dea::XMLUtil.new
      @isSetupDone = Hash.new
    end
    
    def manageDependence3(txContext, depMgr, compLifecycleMgr)
      puts "vc: alg manageDependence3(),compLifecycleMgr nil? #{compLifecycleMgr == nil}"
      
      #在ondemand过程中，这里没被调用？
      compStatus = compLifecycleMgr.compStatus #CompStatus
      
      txDepRegistry = NodeManager.instance.getTxDepMonitor(compLifecycleMgr.compObj.identifier).txDepRegistry
      
      case compStatus
      when CompStatus::NORMAL
        puts "#{compLifecycleMgr.compObj.identifier}.vc manageDependence3 , status = normal"
        doNormal(txContext,depMgr,compLifecycleMgr, txDepRegistry)
      when CompStatus::VALID
         puts "#{compLifecycleMgr.compObj.identifier}.vc manageDependence3 , status = valid"
        doValid(txContext, depMgr, txDepRegistry)
      when CompStatus::ONDEMAND
         puts "#{compLifecycleMgr.compObj.identifier}.vc manageDependence3 , status = ondemand"
        doOndemand(txContext,compLifecycleMgr , depMgr, txDepRegistry)
      when CompStatus::UPDATING
        puts "vc: manageDependence3 status=updating"
        doValid(txContext,depMgr,txDepRegistry)
      when CompStatus::FREE
         puts "#{compLifecycleMgr.compObj.identifier}.vc manageDependence3 , status = free"
        doValid(txContext, depMgr,txDepRegistry)
      else
        puts "vc: in else : comStatus: #{compStatus}"
       end 
    end
    
    def manageDependence4(operationType, params, depMgr, compLifecycleMgr)
                        #DepOperationType , Map<String,String>
                        puts "vc. manageDependence4 params = #{params}"
        if compLifecycleMgr.compStatus == CompStatus::NORMAL
          puts "vc.manageDependence4 , compstatus = normal"#怎么感觉好像停在这里了？
          return true
        end      
        
        manageDefResult = false;
        
        sourceComp = params["srcComp"]
        targetComp = params["targetComp"]
        rootTx = params["rootTx"]
        
        case operationType
        when DepOperationType::NOTIFY_FUTURE_CREATE
          puts "vc: doNotifyFutureCreate"
          manageDepResult = doNotifyFutureCreate(sourceComp,targetComp,rootTx,depMgr)
        when DepOperationType::NOTIFY_FUTURE_REMOVE
          puts "vc: doNotifyFutureRemove"
          manageDepResult = doNotifyFutureRemove(sourceComp,targetComp,rootTx,depMgr)
        when DepOperationType::NOTIFY_START_REMOTE_SUB_TX
          puts "vc: deprecated!"
        when DepOperationType::ACK_SUBTX_INIT
          puts "vc: before process ACK_SUBTX_INIT"
          parentTxID = params["parentTx"]
          subTxID = params["subTx"]
          manageDepResult = doAckSubTxInit(sourceComp,targetComp,rootTx,parentTxID,
                                             subTxID,compLifecycleMgr,depMgr)
          puts "vc: after manageDepResult = #{manageDepResult}"                                    
        when DepOperationType::NOTIFY_PAST_CREATE
          puts "vc : before process NOTIFY_PAST_CREATE"
          manageDepResult = doNotifyPastCreate(sourceComp,targetComp,rootTx,depMgr)
          puts "vc : after process NOTIFY_PAST_CREATE"
          
        when DepOperationType::NOTIFY_PAST_REMOVE
            puts "vc : notify_past_remove"
            manageDepResult = doNotifyPastRemove(sourceComp,targetComp,rootTx,depMgr)
        when DepOperationType::NOTIFY_REMOTE_UPDATE_DONE
            puts "vc : notify_remove_update_done"
            manageDepResult = doNotifyRemoteUpdateDone(sourceComp,targetComp,depMgr)    
        else
           puts "vc: in case else"      
        end 
        
        return manageDepResult
    end
    
    def doNormal(txCtx,depMgr,compLifecycleMgr,txDepRegistry)
       # TransactionContext
       
       if txCtx.eventType == TxEventType::TransactionEnd
          hostComp = txCtx.hostComponent
          ondemandSyncMonitor = compLifecycleMgr.compObj.ondemandSyncMonitor
          ondemandCondition = compLifecycleMgr.compObj.ondemandCondition
          
          #  do we need sync here , cause we only have one DEA,one Component,one Mgr
          ondemandSyncMonitor.synchronize do 
            rootTx = txCtx.getProxyRootTxId(depMgr.scope)
            if compLifecycleMgr.compStatus == CompStatus::NORMAL
              size = depMgr.getTxs().size
              puts "vc : depMgr.getTxs().size=#{size}"
              
              depMgr.getTxs().delete(txCtx.currentTx)
              depMgr.txLifecycleMgr.rootTxEnd(hostComp, rootTx) 
              
              puts "vc : remove tx from TxRegistry and TxDepMonitor , local tx = #{txCtx.currentTx} "
              
              puts "vc : rootTx: #{rootTx}"
              
              return
            else
              if compLifecycleMgr.compStatus == CompStatus::ONDEMAND
                puts "vc : ondemandSyncMonitor.wait()"
                #  TODO need testing here we call ondemandSyncMonitor.wait()
                ondemandCondition.wait()
              end
            end
            
          end
          
          doValid(txCtx,depMgr,txDepRegistry)
          
       end
    end
    
    def doValid(txContext,depMgr, txDepRegistry)
      # TransactionContext
      puts "vc.doValid #{txContext.hostComponent}"
      txEventType = txContext.eventType #String
      
      scope = depMgr.scope
      
      rootTx = txContext.getProxyRootTxId(scope)
      
      if(rootTx == nil)
        puts "vc: InvocationSequence"
        puts txContext.invocationSequence
        
        puts "vc : hostComp:"
        puts txContext.hostComponent
        puts "vc : real root: "
        puts txContext.rootTx
        
      end
      
      currentTx = txContext.currentTx
      hostComp = txContext.hostComponent
      
      inDepRegistry = depMgr.inDepRegistry
      outDepRegistry = depMgr.outDepRegistry
      
      futureComponents = txDepRegistry.getLocalDep(currentTx).futureComponents # Set
      
      if txEventType == TxEventType::TransactionStart
        lfe = Dependence.new(FUTURE_DEP,rootTx,hostComp, hostComp,nil,nil)
        
        if !inDepRegistry.contain(lfe)
          puts "vc.inDepRegistry.add future"
          inDepRegistry.addDependence(lfe)
          puts
        end
        
        if !outDepRegistry.contain(lfe)
          puts "vc.outDepRegistry.add future"
          outDepRegistry.addDependence(lfe)
        end
        
         lpe = Dependence.new(PAST_DEP,rootTx,hostComp,hostComp,nil,nil)
        
        if  !inDepRegistry.contain(lpe)# local past edge
          puts "vc.inDepRegistry.add past"
          inDepRegistry.addDependence(lpe)
          
        end
        
        if !outDepRegistry.contain(lpe)
          puts "vc.outDepRegistry.add past"
          outDepRegistry.addDependence(lpe)
        end
        
        if rootTx == currentTx
          #current Tx is root
          @isSetupDone[rootTx]=false 
          # must interceptor request in router 拦截路由器的请求？
          # 即使更新完成了，还是false？？？
        else
          # ACK_SUBTX_INIT 当前事务不是根事务，通知parent，开启了一个新的事务
          #这里确实是，同步通知的，hello等待call的回复？
          payload = ConsistencyPayloadCreator.createPayload6(hostComp,
                             txContext.parentComponent,rootTx,DepOperationType::ACK_SUBTX_INIT,
                             txContext.parentTx,txContext.currentTx)
                             
          #   notify need tesing : DepNotifyService.synPost()
          #
          puts "#{txContext.hostComponent}.vc: notify parent ,  that a new sub-tx start"
          depNotify(hostComp,txContext.parentComponent,payload)
                             
        end
      elsif txEventType == TxEventType::DependencesChanged
        puts "#{txContext.hostComponent}.vc.doValid type = DependenceChanged"
        futureDepsInODR = outDepRegistry.getDependencesViaType(FUTURE_DEP)
        # futureDepsInOutDepRegistry
        futureDepSameRoot = Set.new # concurrentSkipListSet<Dependence>
        
        futureDepsInODR.each{|dep|
          if dep.rootTx == rootTx
            futureDepSameRoot << dep
          end
          
          }  
          
          hasFutureInDep = false
          
          futureDepsInIDR = inDepRegistry.getDependencesViaType(FUTURE_DEP)
          #futureDepsInInDepRegistry
          futureDepsInIDR.each{|dep|
            
           if dep.rootTx == rootTx
              hasFutureInDep = true     
              break                                                                                                
            end
            }
           
           puts "#{txContext.hostComponent}.vc.doValid hasFutureInDep = #{hasFutureInDep} "
           # during tx running , find some components will never be used anymore
           # if current component do not have any other future in deps , 
           # delete  the future deps from current to sub components 
            # hasFutureInDeps
            futureDepSameRoot.each{|dep|
              puts "futureDepSameRoot, dep = #{dep}"
              if !hasFutureInDep && !futureComponents.include?(dep.targetCompObjIdentifier) && !dep.targetCompObjIdentifier == hostComp
                  outDepRegistry.removeDependence(dep.type , dep.rootTx,dep.srcCompObjIdentifier ,dep.targetCompObjIdentifier )    
                  
                  payload = ConsistencyPayloadCreator.createPayload4(hostComp,dep.targetCompObjIdentifier,rootTx,DepOperationType::NOTIFY_FUTURE_REMOVE)
                  
                  puts "payload  #{payload}!!! dep changed , notify #{dep.targetCompObjIdentifier}"
                  ## here notify testing TODO
                  depNotify(hostComp,dep.targetCompObjIdentifier,payload)
                      
               else
                  puts "vc.doValid dependencesChanged , in else" #TODO 测试，为啥hasFuture是true的？
                  puts "futureComps = #{futureComponents}"
                  puts "dep.target = #{dep.targetCompObjIdentifier}"
                  puts "hostComp = #{hostComp}"  
              end
                
                puts
              }
              
      elsif txEventType == TxEventType::TransactionEnd
            # if current Tx is not root , need to notify parent sub_tx_end
            
            if   currentTx != rootTx
              puts "#{txContext.hostComponent}.vc: handle TxEnd , current Tx is not root , do nothing "
              puts "\t currentTx = #{currentTx}"
              puts  "\t rootTx = #{rootTx}"
            else
              # current tx is root tx 如果是根事务，inDepResigtry删除future边和past边
              puts "inDepRegistry remove Future dep"
              inDepRegistry.removeDependence(FUTURE_DEP,rootTx,hostComp , hostComp)
              puts "inDepRegistry remove past dep"
              inDepRegistry.removeDependence(PAST_DEP,rootTx,hostComp,hostComp)
              # outDepRegistry删除future边和past边
              puts "outDepRegistry remove Future dep \t"
              outDepRegistry.removeDependence(FUTURE_DEP,rootTx,hostComp,hostComp)
              puts "outDepRegistry remove past dep \t"
              outDepRegistry.removeDependence(PAST_DEP,rootTx,hostComp,hostComp)
              
              removeAllEdges(hostComp,rootTx,depMgr)
              
              puts "vc.doValid: handle TxEnd msg : rootTx End hostComp = #{hostComp} , rootTx = #{rootTx}" 
              
              @isSetupDone.delete currentTx
            end
            
            depMgr.getTxs().delete currentTx
            
      else
         # up receiving FirstRequeceService
         # if current tx is root tx , we need to start set up
           # targetRef = {}# Set
            targetRef = nil
            if scope != nil 
              targetRef = Set.new(scope.subComponents[hostComp])
              
            else
              targetRef = Set.new(depMgr.getStaticDeps())
              
            end
            
            if rootTx == currentTx && ( @isSetupDone[rootTx] == nil && @isSetupDone[rootTx] ==false)
                 fDeps = txDepRegistry.getLocalDep(currentTx).futureComponents #Set
                 
                 fDeps.each{|targetComp|
                     if !targetRef.include?(targetComp)
                       next
                     end
                     
                     dep = Dependence.new(FUTURE_DEP,currentTx,hostComp,targetComp,nil,nil)
                     
                     outDepRegistry.addDependence(dep)
                     
                     payload = ConsistencyPayloadCreator.createPayload4(hostComp,targetComp,currentTx,DepOperationType::NOTIFY_FUTURE_CREATE)
                     puts payload
                     #TODO
                     #Notify testing
                     puts "vc: FirstRequestService , notify target, #{targetComp}"
                     depNotify(hostComp,targetComp,payload)
          
                 }
                 
                 @isSetupDone[rooTx] = true
            end
                 
      end
    end
    
    
    def doOndemand(txContext,compLifecycleMgr,depMgr,txDepRegistry)
      puts "vc: doOndemand!!!"
      ondemandSyncMonitor = compLifecycleMgr.compObj.ondemandSyncMonitor
      
      ondemandSyncMonitor.synchronize do 
          if compLifecycleMgr.compStatus == CompStatus::ONDEMAND
            #TODO
            #ondemandSyncMonitor.wait()???
            puts "--------------ondemandSyncMonitor.wait()"
          end
      end
      
      doValid(txContext,depMgr,txDepRegistry)
    end
    
    
    def doNotifyFutureCreate(sourceComp,targetComp,rootTx,depMgr)
      puts "vc.doNotifyFutureCreate #{sourceComp} ---> #{targetComp} rootTX: #{rootTx}"
      
      inDepRegistry = depMgr.inDepRegitry
      outDepRegistry = depMgr.outDepRegistry
      
      dep = Dependence.new(FUTURE_DEP,rootTx,sourceComp,targetComp,nil,nil)
      
      inDepRegistry.addDependence(dep)
      
      scope = depMgr.scope
      
      targetRef= Set.new
      if(scope != nil)
        targetRef = Set.new(scope.getSubComponents(targetComp))
      else
        targetRef = Set.new(depMgr.staticDeps)
      end
      
      
      targetRef.each{|str|
        
        futureDep = Dependence.new(FUTURE_DEP,rootTx,targetComp,str,nil,nil)
        
        outDepRegistry.addDependence(futureDep)
        
        payload = ConsistencyPayloadCreator.createPayload4(targetComp, str,rootTx,DepOperationType::NOTIFY_FUTURE_CREATE)
        
        #TODO notify !!! testing
         depNotify(targetComp,str,payload)
        #depNotifyService.syncPost(targetComp, str, "ALGORITHM_TYPE","DEPENDENCY_MSG",payload)
        }
        
        return true
    end
    
    def doNotifyPastRemove(sourceComp,targetComp,rootTx,depMgr)
      puts "vc.doNotifyPastRemove #{sourceComp} ---> #{targetComp} rootTx: #{rootTx}"
      
      inDepRegistry = depMgr.inDepRegistry
      # 这里调用check for freeness
      inDepRegistry.removeDependence(PAST_DEP,rootTx,sourceComp,targetComp)
      
      return removeAllEdges(targetComp,rootTx,depMgr)
      
    end
    
    def doNotifyPastCreate(sourceComp,targetComp,rootTx,depMgr)
      puts "vc.doNotifyPastCreate: #{sourceComp} ---> #{targetComp} rootTx #{rootTx}"
      
      inDepRegistry = depMgr.inDepRegistry
      
      dep = Dependence.new(PAST_DEP,rootTx,sourceComp,targetComp,nil,nil)
      
      inDepRegistry.addDependence(dep)
      
      txs = depMgr.getTxs() # Map<String , TxContext>
      
      flag = false
      
      txs.each{|key, tc|
        
        if tc.getProxyRootTxId(depMgr.scope) == rootTx && tc.eventType!=TxEventType::TransactionEnd && !tc.isFakeTx
          puts "true"
          flag = true
          break
        end
        
        }
        
        outDepRegistry = depMgr.outDepRegistry
        
        if !flag
              puts "vc.delete future/past on #{targetComp}, tx: #{rootTx}"
              puts "inDepRegistry.remove future dep , "
              inDepRegistry.removeDependence(FUTURE_DEP,rootTx,targetComp , targetComp)
               puts "inDepRegistry.remove past dep , \t "
              inDepRegistry.removeDependence(PAST_DEP,rootTx,targetComp,targetComp)
               puts "outDepRegistry.remove future dep , "
              outDepRegistry.removeDependence(FUTURE_DEP,rootTx,targetComp,targetComp)
               puts "outDepRegistry.remove past dep , \t"
              outDepRegistry.removeDependence(PAST_DEP,rootTx,targetComp,targetComp)
        end
        
        depMgr.dependenceChanged(targetComp)
        
        hostComp = depMgr.compObj.identifier
        
        txDepRegistry = NodeManager.instance.getTxDepMonitor(hostComp).txDepRegistry
        
        removeFutureEdges4(targetComp,rootTx,depMgr,txDepRegistry)
        
        return true
    end
    
    
    def doNotifySubTxEnd(sourceComp,targetComp,rootTx,parentTx,subTx,compLifecycleMgr,depMgr)
      name = compLifecycleMgr.compObj.identifier
      puts "#{name}.vc.doNotifySubTxEnd"
      puts "#{sourceComp} ---> #{targetComp} subTx: #{subTx} \n \t rootTx: #{rootTx} \n \t parentTx = #{parentTx}"
      
      ondemandMonitor = compLifecycleMgr.compObj.ondemandSyncMonitor
      
      ondemandMonitor.synchronize do 
        
        allTxs = depMgr.getTxs()#Map<String,TxContext> 这里为空的原因？应该是depMonitor删了什么东西吧？
        puts "#{name}.vc.doNotifySubTxEnd.allTxs = #{allTxs}"
        txCtx = allTxs[parentTx]
        # puts ""
        #这里断言，txCtx不为空
        if txCtx == nil
          puts "!!!#{name}.vc.doNotifySubTxEnd, should not be nil!"
          return false
        end
        subTxHostComps = txCtx.subTxHostComps
        subTxStatuses = txCtx.subTxStatuses
        
        if compLifecycleMgr.compStatus == CompStatus::NORMAL
          return true
        end
        
        scope = depMgr.scope
        
        if scope != nil && !scope.subComponents[targetComp].include?(sourceComp) # scope.subComponents[targetComp] = Set
          
          return true
          
        end
        
        outDepRegistry = depMgr.outDepRegistry
        
        dep =  Dependence.new(PAST_DEP,rootTx,targetComp,sourceComp,nil,nil)
        
        outDepRegistry.addDependence(dep)
        payload = ConsistencyPayloadCreator.createPayload4(targetComp,sourceComp,rootTx,DepOperationType::NOTIFY_PAST_CREATE)
        puts "#{name}.vc.payload : #{payload}"
        puts "#{name}.vc: doNotifySubTxEnd, notify sourceComp = #{sourceComp}"
        depNotify(targetComp,sourceComp,payload)
        #  need testing
         
        return true
      end
    end
    
    # be notified that a sub tx being initiated
    def doAckSubTxInit(sourceComp,targetComp,rootTx,parentTxID,subTxID,compLifecycleMgr,depMgr)
      name = compLifecycleMgr.compObj.identifier
      puts "#{name}.vc.doAckSubTxInit "
      puts "#{sourceComp} --> #{targetComp} subTx: #{subTxID} rootTx: #{rootTx}"
      
      ondemandSyncMonitor = compLifecycleMgr.compObj.ondemandSyncMonitor
      
      
      ondemandSyncMonitor.synchronize do 
        
        allTxs = depMgr.getTxs() #Map<String,TxContext>
        puts "#{name}.vc.doAckSubTxInit allTxs = #{allTxs}"
        txCtx = allTxs[parentTxID]
        if txCtx == nil
          puts "!!!#{name}.vc.doAckSubTxInit txCtx = allTxs[parentTxId] is nil"
          return false
        end
        subTxHostComps = txCtx.subTxHostComps # MAp<String,>
        subTxStatuses = txCtx.subTxStatuses #Map<String, >
        
        subTxHostComps[subTxID] = sourceComp
        subTxStatuses[subTxID] = TxEventType::TransactionStart
        
        if compLifecycleMgr == CompStatus::NORMAL
          return true
        end
        puts "#{name}.vc.doAckSubTxInit , before call removeFutureEdges5"
        return removeFutureEdges5(targetComp,rootTx,parentTxID,subTxID,depMgr)
        
        
        
      end
      
    end
    
    
    #receiver NotifyFutureRemove
    #try to remove src --> target future dep
    
    def doNotifyFutureRemove(sourceComp,targetComp,rootTx,depMgr)
      hostComp = depMgr.compObj.identifier
      puts "#{hostComp}.vc.doNotifyFutureRemove #{sourceComp} --> #{targetComp}   rootTx: #{rootTx}"
      
      inDepRegistry = depMgr.inDepRegistry
      inDepRegistry.removeDependence(FUTURE_DEP, rootTx, sourceComp, targetComp)
      puts "#{hostComp} after removeDep(Future) , inDepRegistry = #{inDepRegistry}"
      
      txDepRegistry = NodeManager.instance.getTxDepMonitor(hostComp).txDepRegistry
      
      result = removeFutureEdges4(targetComp,rootTx,depMgr,txDepRegistry)
      result 
    end
    
    def depNotify(hostComp,comp,payloadSend)
         puts "#{hostComp}.vc : called dep notify service sync client"
         comm =  @xmlUtil.getAllComponentsComm
         # puts "comm"
         ip =  "192.168.12.34"
         port =  comm[comp]
         
         puts "#{ip},#{port}"
  #                
         Dea::SynCommClient.sendMsg(ip,port,hostComp,comp,
                                          "CONSISTENCY",MsgType::DEPENDENCE_MSG,payloadSend,"Sync")
    end
    
    def depNotifyAsync(hostComp,comp,payloadSend)
         puts "#{hostComp}.vc : called dep notify service async "
         comm =  @xmlUtil.getAllComponentsComm
         # puts "comm"
         ip =  "192.168.12.34"
         port =  comm[comp]
         
         puts "#{ip},#{port}"
  #               
         Dea::ASynCommClient.sendMsg(ip,port,hostComp,comp,
                                          "CONSISTENCY",MsgType::DEPENDENCE_MSG,payloadSend,"Async")
    end
    
     def doNotifyRemoteUpdateDone(sourceComp,hostComp,depMgr)
       puts "vc: #{hostComp} received notfiyRemoteUpdateDone from #{sourceComp}" 
       
       scope = depMgr.scope
       parentComps = Set.new
       if scope!=nil
         parentComps = scope.parentComponents[hostComp]
       else
         parentComps = depMgr.compObj.staticInDeps
         
       end
       
       parentComps.each{|comp|
        
         #  notify  testing
          payload = ConsistencyPayloadCreator.createRemoteUpDateIsDonePayload(hostComp,comp,DepOperationType::NOTIFY_REMOTE_UPDATE_DONE)
          depNotifyAsync(hostComp,comp,payload)
         
         # depNotifyService.asynPost(hostComp,comp, "Consistency","Dependence_msg",payload)
         }
         
         depMgr.getRuntimeDeps().clear
         depMgr.getRuntimeInDeps().clear
         
          depMgr.scope = nil

          updateMgr = Dea::NodeManager.instance.getUpdateManager(hostComp)
          
          updateMgr.remoteDynamicUpdateIsDone()
         
         return true
      end
    
    #try to remove future dep when receive ACK_SUB_INIT
      def removeFutureEdges5(currentComp,rootTx,currentTxID,subTxID,depMgr)
        puts "vc.removeFutureEdges5, curComp = #{currentComp} , "
        outDepRegistry = depMgr.outDepRegistry
        inDepRegistry = depMgr.inDepRegistry
        
        outFutureDeps = outDepRegistry.getDependencesViaType(FUTURE_DEP)
        outFutureOneRoot = Set.new # HashSet<Dependence>
        
        outFutureDeps.each{|dep|
          puts "outFutureDeps : dep #{dep}"
          if dep.rootTx == rootTx && dep.srcCompObjIdentifier != dep.targetCompObjIdentifier
            puts "if , add one out future #{dep}"
            outFutureOneRoot << dep
          else
            puts "else , rootTx = #{rootTx} , dep.rootTx = #{dep.rootTx} , "
            puts "src = #{dep.srcCompObjIdentifier},target = #{dep.targetCompObjIdentifier}"  
          end
          
          }
          
        inFutureFlag = false
        futureDeps = inDepRegistry.getDependencesViaType(FUTURE_DEP)
        
        futureDeps.each{|dep|
          puts "vc.remove5 futureDep : dep= #{dep}"
          if dep.rootTx == rootTx && dep.srcCompObjIdentifier!= dep.targetCompObjIdentifier
            puts "vc.remove5: inFutureFlag change to true"
            inFutureFlag = true
            break
          end
          }   
        
        if !inFutureFlag
          txDepMonitor = Dea::NodeManager.instance.getTxDepMonitor(currentComp)
          puts "in future flag == false"
          outFutureOneRoot.each{|dep|
            puts "outFutureOneRoot : dep = #{dep}"
            isLastUse = txDepMonitor.isLastUse(currentTxID, dep.targetCompObjIdentifier, currentComp)
            if isLastUse
                payload = Dea::ConsistencyPayloadCreator.createPayload4(dep.srcCompObjIdentifier, dep.targetCompObjIdentifier, dep.rootTx,DepOperationType::NOTIFY_FUTURE_REMOVE)
                #  notify testing  
                puts "#{currentComp}.vc: notify  future_remove \n\t payload = #{payload}"
                depNotify(dep.srcCompObjIdentifier,dep.targetCompObjIdentifier,payload)
            else
              puts "isLastUse false"  
            end
            }
        else
          puts "inFutureFlag = true"    
        end   
        puts "vc.remove5 inFutureFlag = #{inFutureFlag}"
        return true
        
      end
    
      #try to remove future dep when receive NOTIFY_PAST_CREATE
      
      # according to the condition to decide whether need to remove the future dep
      
      def removeFutureEdges4(currentComp,rootTx,depMgr,txDepRegistry)
        puts "#{currentComp}.vc.removeFutureEdge4 "
        outDepRegistry = depMgr.outDepRegistry
        inDepRegistry = depMgr.inDepRegistry
        
        outFutureDeps = outDepRegistry.getDependencesViaType(FUTURE_DEP)
        outFutureOneRoot = Set.new # HashSet<Dependence>
        
        outFutureDeps.each{|dep|
          
          if dep.rootTx == rootTx && dep.srcCompObjIdentifier != dep.targetCompObjIdentifier
               outFutureOneRoot << dep
          end
          }
          
       inFutureFlag = false
       
       futureDeps = inDepRegistry.getDependencesViaType(FUTURE_DEP)
       
       futureDeps.each{|dep|
         if dep.rootTx == rootTx && dep.srcCompObjIdentifier != dep.targetCompObjIdentifier
           inFutureFlag = true
           break
         end
         }   
         
        willNotUseFlag = true
       
       outFutureOneRoot.each{|dep|
         
         if !inFutureFlag
           localTxs = depMgr.getTxs() #Map<String , TxContext>
           
           localTxs.each{|key,txCtx|
             
             if txCtx.isFakeTx
               next
             end
             
             fDeps = txDepRegistry.getLocalDep(txCtx.currentTx).futureComponents #Set<String>
             
             fDeps.each{|fdep|
               
               if fdep == dep.targetCompObjIdentifier && txCtx.getProxyRootTxId(depMgr.scope) == rootTx
                 willNotUseFlag = false
                 break
               end
               }
             
             if !willNotUseFlag
               break
             end
             
             }
             
             if willNotUseFlag
               puts "#{currentComp}.vc.removeFutureEdges4 will not use in future"
               scope = depMgr.scope
               
               if scope!=nil && !scope.subComponents[dep.srcCompObjIdentifier].include?(dep.targetCompObjIdentifier)
                 next
               end
               
               outDepRegistry.removeDependenceViaDep(dep)
               puts "after removeDep,outDepRegistry = #{outDepRegistry}"
               payload = ConsistencyPayloadCreator.createPayload4(dep.srcCompObjIdentifier, dep.targetCompObjIdentifier, dep.rootTx,DepOperationType::NOTIFY_FUTURE_REMOVE)
               #  notify testing
               puts "#{currentComp}.vc.removeFutureEdges4 payload #{payload}"#
               #syncPost(dep.srcCompObjIdentifier, dep.targetCompObjIdentifier , "algorithm_type" , "dependence_msg", payload)
               depNotify(dep.srcCompObjIdentifier,dep.targetCompObjIdentifier,payload)
             else
               puts "#{currentComp}.removeFutureEdges4 , willNotUseFlag = false"
             end
         end
         
         }
        
         return true
      end
      
      def removeAllEdges(hostComp,rootTx, depMgr)
        puts "vc.removeAllEdges , rootTx = #{rootTx}"
        rtOutDeps = depMgr.getRuntimeDeps()
        
        rtOutDeps.each{|dep|
          puts "#{hostComp}.vc.removeAllEdges dep = #{dep}"
          if dep.rootTx == rootTx && dep.type == FUTURE_DEP && dep.srcCompObjIdentifier != dep.targetCompObjIdentifier
            puts "vc.removeAllEdges rootTx = #{rootTx} , type = future ,src!=target, notify_future_remove"
            payload = Dea::ConsistencyPayloadCreator.createPayload4(hostComp,dep.targetCompObjIdentifier, rootTx,DepOperationType::NOTIFY_FUTURE_REMOVE)
              #  notify testing
              #synPost(hostComp, dep.targetCompObjIdentifier, "consistency","dependency_msg",payload)
              depNotify(hostComp,dep.targetCompObjIdentifier,payload)
          elsif dep.rootTx == rootTx && dep.type == PAST_DEP && dep.srcCompObjIdentifier != dep.targetCompObjIdentifier
            puts "vc.removeAllEdges , rootTx = #{rootTx} , type =past,src!=target , notify_past_remove"
            payload = Dea::ConsistencyPayloadCreator.createPayload4(hostComp,dep.targetCompObjIdentifier, rootTx,DepOperationType::NOTIFY_PAST_REMOVE)
              #  notify testing
              depNotify(hostComp,dep.targetCompObjIdentifier,payload)
              
          else
              puts "vc.removeAllEdges else, dep=  #{dep}" #这里应该说明，rootTx ！= dep.rootTx
          end
          puts
          if dep.rootTx == rootTx
            rtOutDeps.delete(dep)
          end
          }
          
          rtInDeps = depMgr.getRuntimeInDeps()
          
          isPastDepExist = false
          
          rtInDeps.each{|dep|
            
            if dep.rootTx == rootTx
              isPastDepExist = true
              break
            end
            }
            
          #remove tx
          
          depMgr.getTxs().each{|key,txCtx| #Map<String , TxContext>
            
            if txCtx.getProxyRootTxId(depMgr.scope) == rootTx
              #  have a bug>>>???
              
              if !isPastDepExist
                 depMgr.getTxs().each{|k,inCtx|
                   
                   if inCtx.getProxyRootTxId(depMgr.scope) == rootTx
                     # puts "It is strange!!!"
                     #  tai qi pa l ...
                     depMgr.getTxs().delete(k)
                   end
                   }
              end
                
            end
            
            }  
            
          puts "#{hostComp}.vc.removeAllEdges, before rootTx end"
          depMgr.getTxLifecycleMgr().rootTxEnd(hostComp,rootTx)
          
          return true  
      end
      
      
      def getDepsBelongToSameRootTx(rootTxID,allDeps) # String, Set<Dependence>
        
        result = Set.new #Set<Dependence>
        
        allDeps.each{|dep|
          
          if dep.rootTx == rootTxID
            result << dep
          end
          }
          
          result
      end
      
      def getAlgorithmType
        return "VersionConsistency"
      end
      
      def getOldVersionRootTxs(allInDeps) # Set<Dependence>
          oldRootTx = Set.new #Set<String>
          allInDeps.each{|dep|
            
               if dep.type == PAST_DEP
                 oldRootTx << dep.rootTx
               end
            }
          
          inDepsStr=""
          
          allInDeps.each{|dep|
            
            inDepsStr += "\n" + dep.to_s
            
           
            }
            
          puts "vc.getOldVersionRootTxs: inDepsStr = #{inDepsStr}"  
          
          outDepsStr=""
          
          oldRootTx.each{|tx|
            outDepsStr += "\n" + tx
            
            }
            
          puts "vc.getOldVersionRootTxs: oldRootTX = #{outDepsStr}"
          
          # puts "in consistencey algorithm (allInDeps) #{allInDeps}"
          
          oldRootTx   
      end
      
      
      def readyForUpdate(compIdentifier,depMgr) #TODO to be test
        
        rtInDeps = depMgr.getRuntimeInDeps()
        
        # 
        allRootTxs = Set.new(rtInDeps)
        
        
         
         
        allRootTxs.each{|dep|
          
          puts "Algorithn inReady? #{dep}"
          }
          
          
        freeFlag = true
        allRootTxs.each{|tmpRoot|
          deps = getDepsBelongToSameRootTx(tmpRoot, rtInDeps)
          pastFlag =false
            
          futureFlag = false
          deps.each{|dep|
            
            if dep.type ==  PAST_DEP
              pastFlag = true
            else
              futureFlag = true
            end
            }
            
            if pastFlag && futureFlag
              puts "deps: #{deps}"
              freeFlag = false
              break
            end
          
          }  
          
          freeFlag
      end
      
      
      
      def isBlockRequiredForFree(algorithmOldVersionRootTxs , txContext, isUpdateReqRCVD, depMgr) #Set<String>
        
        if !isUpdateReqRCVD
          return false
          
          
        end
        
        rootTx = txContext.getProxyRootTxId(depMgr.scope)
        
        if  algorithmOldVersionRootTxs != nil && algorithmOldVersionRootTxs.include?(rootTx)
          
          realRootTxId = txContext.rootTx
          
          puts "real rootTxId : #{realRootTxId} proxyRootTxId: #{rootTx} not blocked ,\n algorithm : #{algorithmOldVersionRootTxs}"
          return false
        else
          puts "real rootTxId : #{realRootTxId} proxyRootTxId: #{rootTx} is blocked ,\n algorithm : #{algorithmOldVersionRootTxs}"
          return true
        end
      end
      
      
      
      def updateIsDone(hostComp,depMgr)
        puts "vc : called updateIsDone"
        @isSetupDone.clear 
        # puts "a"
        scope = depMgr.scope
        # puts "b"
        parentComps = Set.new
        # puts "c"
        if scope != nil
          # puts  "scope not nil"
          parentComps = scope.parentComponents[hostComp]
          # puts scope.parentComponents[hostComp].size
        else
          puts "scope nil"
          parentComps = depMgr.compObj.staticInDeps
          puts depMgr.compObj.staticInDeps.size
        end
        
        puts parentComps.size
        
        parentComps.each{|comp|
          puts "parent comp = #{comp} "
          payloadSend = Dea::ConsistencyPayloadCreator.createRemoteUpDateIsDonePayload(hostComp,comp, DepOperationType::NOTIFY_REMOTE_UPDATE_DONE)
            
            
         comm =  @xmlUtil.getAllComponentsComm
         puts "comm"
         ip =  "192.168.12.34"
         port =  comm[comp]
         
         puts "#{ip},#{port}"
  #               paras=  ip,port,srcIdentifier,targetIdentifier,protocol,msgType,payload,commType
         Dea::ASynCommClient.sendMsg(ip,port,hostComp,comp,
                                          "CONSISTENCY",MsgType::DEPENDENCE_MSG,payloadSend,"Async")
                                          
          #  notify testing
           }
          
          depMgr.getRuntimeDeps().clear
          depMgr.getRuntimeInDeps().clear
          
          depMgr.scope = nil
          return true
      end
      
      
      def initiate(identifier, depMgr)
        
      end
      
      def initLocalSubTx(txContext,compLifecycleMgr,depMgr)
        puts "#{compLifecycleMgr.compObj.identifier}.vc : initLocalSubTx"
        #该方法原来是在bufferInterceptor中执行的，可能被拦截。比如说，ondemand过程中
        hostComp = txContext.hostComponent
        fakeSubTx = txContext.currentTx
        rootTx = txContext.rootTx
        parentTx = txContext.parentTx
        parentComp = txContext.parentComponent
        
        rtInDeps = depMgr.getRuntimeInDeps()
        rtOutDeps = depMgr.getRuntimeDeps()
        
        ondemandMonitor = compLifecycleMgr.compObj.ondemandSyncMonitor
        
        ondemandMonitor.synchronize do
          
          rootTx = txContext.getProxyRootTxId(depMgr.scope)
          
          if compLifecycleMgr.compStatus == CompStatus::ONDEMAND
            #如果是在ondemand过程中接受到的，才去添加future和past边?
            lfe = Dependence.new(FUTURE_DEP,rootTx,hostComp,hostComp,nil,nil)
            puts "vc: lfe=#{lfe}"
            if !rtInDeps.include?(lfe)
              rtInDeps << lfe
            end
            
            if !rtOutDeps.include?(lfe)
              rtOutDeps << lfe
            end
            
            lpe = Dependence.new(PAST_DEP,rootTx,hostComp,hostComp,nil,nil)
            puts "vc: lpe=#{lpe}"
            if !rtInDeps.include?(lpe)
              rtInDeps << lpe
            end
            
            if !rtOutDeps.include?(lpe)
              rtOutDeps << lpe
            end
            
            
            #ACK_SUBTX_INIT
            
            payload = ConsistencyPayloadCreator.createPayload6(hostComp,parentComp,rootTx,DepOperationType::ACK_SUBTX_INIT , parentTx,fakeSubTx)
            puts "payload = #{payload}"
            #TODO notify testing
            #synPost(hostComp, parentComp,"consistency", "dependency_msg" , payload)  
            depNotify(hostComp,parentComp,payload)
          end
        end
        
        return true
      end
      
      
      def notifySubTxStatus(subTxStatus, invocationCtx,compLifecycleMgr, depMgr,proxyRootTxId)
        
        name = compLifecycleMgr.compObj.identifier
        
        parentTx = invocationCtx.parentTx
        subTx = invocationCtx.subTx
        subComp = invocationCtx.subComp
        rootTx = invocationCtx.rootTx
        curComp = invocationCtx.parentComp
        
        puts "#{name}.vc: SubTxStatus = #{subTxStatus} , proxyRootTxId = #{proxyRootTxId} \n \t invocationCtx = #{invocationCtx}"
        if subTxStatus == TxEventType::TransactionStart
          
          ondemandSyncMonitor = compLifecycleMgr.compObj.ondemandSyncMonitor
          
          ondemandSyncMonitor.synchronize do
            allTxs = depMgr.getTxs() # Map<String,TxContext>
            puts "vc: allTx =  #{allTxs}"
            puts "vc: parentTx = #{parentTx}"
            txCtx = allTxs[parentTx]
            puts "vc.notifySubTxStatus : #{txCtx}"
            if   txCtx
              subTxHostComps = txCtx.subTxHostComps # Map<String,String>
              subTxStatuses = txCtx.subTxStatuses
              
              subTxHostComps[subTx]=subComp
              subTxStatuses[subTx]=TxEventType::TransactionStart
            else
              puts "vc.notifySubTx : txCtx == nil"
            end
          end
          
          return true
        elsif subTxStatus == TxEventType::TransactionEnd
          puts "vc.notifySubTxStatus subTxStatus=TxEnd"
          return doNotifySubTxEnd(subComp,curComp,proxyRootTxId,parentTx,subTx,compLifecycleMgr,depMgr)
        else
          puts "vc: unexpected sub transaction status #{subTxStatus}"
          return false
        end
      end
      
      
      
      
      
      
      
      
      
      
      
      
      
      
      
    
  end
end
