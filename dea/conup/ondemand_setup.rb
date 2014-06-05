# UTF-8
require 'eventmachine'
require "steno"
require "steno/core_ext"
require 'json'
require "set"
require "monitor"
require_relative "./tx_dep_registry"
require_relative "./scope"
require_relative "./dynamic_dep_mgr"
require_relative "./comp_lifecycle_mgr"
require_relative "./dep_payload_resolver"
require_relative "./dep_payload"
require_relative "./dep"
require_relative "./comp_status"
require_relative "./xml_util"
require_relative "./ondemand_setup_helper"
require_relative "./dep_op_type"
require_relative "./async_comm_client"
require_relative "./sync_comm_client"
require_relative "./node_mgr"
module Dea
  class VCOndemandSetup < Monitor
    
    attr_accessor :ondemandRequestStatus # Map<String,Map<String,bool>>
    attr_accessor :confirmOndemandStatus #Map<String,Map<String,bool>>
    
    attr_accessor :ondemandHelper
    attr_accessor :compLifecycleMgr
    
    attr_accessor :depMgr
    attr_accessor :isOndemandDone
    
    attr_accessor :txDepRegistry#
    attr_accessor :xmlUtil
    
    def initialize(comp) # ComponentObject
      # @depMgr = Dea::DynamicDepManager.instance(comp) #这两个也是在nodemgr.getOndemandSetupHelper时set
      # @compLifecycleMgr = Dea::CompLifecycleManager.instance(comp)
      
      # we don't new a helper here, instead , we set helper, when we want to use a setup
      @ondemandRequestStatus = {}
      @confirmOndemandStatus = {}
      # txDepMonitor = Dea::TxDepMonitor.instance(comp) #这个不从这里获取，而是在nodemgr.getTxDepMonitor时，set
#       
      # @txDepRegistry = txDepMonitor.txDepRegistry
      @xmlUtil = Dea::XMLUtil.new

      super()
    end
    
    def ondemand(scope) #Scope return boolean
      hostComp =  @ondemandHelper.compObj.identifier
      if !scope
        scope = calcScope() #看来是计算scope错了啊
        
        puts "scope = #{scope}"
      end
      
      @depMgr.scope = scope
      
      if @depMgr.getRuntimeInDeps().size != 0
        @depMgr.getRuntimeInDeps().clear
      end
      
      if @depMgr.getRuntimeDeps.size != 0
        @depMgr.getRuntimeDeps.clear
      end
      
      reqOndemandSetup(hostComp,hostComp)
    end
    
    public
    def ondemandSetup(srcComp,protlcol,payload)
      payloadResolver = Dea::DepPayloadResolver.new(payload)
      
      puts "ondemand_setup: method ondemandSetup :  payload = #{payload}"
      operation = payloadResolver.operation
      
      puts operation
      
      curComp = payloadResolver.getParameter(Dea::DepPayload::TARGET_COMPONENT)
      
      if operation == Dea::DepOperationType::REQ_ONDEMAND_SETUP
        scopeString = payloadResolver.getParameter(Dea::DepPayload::SCOPE)
        
        if scopeString != nil && scopeString != "nil" && scopeString != ""
          scope = Dea::Scope.inverse(scopeString)
          depMgr.scope = scope
        end
        
        reqOndemandSetup(curComp,srcComp)
      elsif operation == Dea::DepOperationType::CONFIRM_ONDEMAND_SETUP
        confirmOndemandSetup(srcComp,curComp)
        
      elsif operation == Dea::DepOperationType::NOTIFY_FUTURE_ONDEMAND
        dep = Dea::Dependence.new(Dea::VersionConsistency::FUTURE_DEP,
                             payloadResolver.getParameter(Dea::DepPayload::ROOT_TX),
                             srcComp,curComp,nil,nil)
        notifyFutureOndemand(dep)
        
      elsif operation == Dea::DepOperationType::NOTIFY_PAST_ONDEMAND
        dep = Dea::Dependence.new(Dea::VersionConsistency::PAST_DEP,
                                  payloadResolver.getParameter(Dea::DepPayload::ROOT_TX),
                                  srcComp,curComp,nil,nil)
        notifyPastOndemand(dep)
        
      elsif operation == Dea::DepOperationType::NOTIFY_SUB_FUTURE_ONDEMAND
        
        dep = Dea::Dependence.new(Dea::VersionConsistency::FUTURE_DEP,
                                  payloadResolver.getParameter(Dea::DepPayload::ROOT_TX),
                                  srcComp,curComp,nil,nil)
        notifySubFutureOndemand(dep)
        
      elsif operation == Dea::DepOperationType::NOTIFY_SUB_PAST_ONDEMAND 
                                              
        dep = Dea::Dependence.new(Dea::VersionConsistency::PAST_DEP,
                                 payloadResolver.getParameter(Dea::DepPayload::ROOT_TX),
                                 srcComp,curComp,nil,nil)
        notifySubPastOndemand(dep)
        
      else
        puts "setup : wrong operation type #{operation}"  
        puts "---------------------------------------------------" 
        puts                                                                                                      
      end
      
      return true
    end
    
    def calcScope
      scope = Dea::Scope.new
      xmlUtil = Dea::XMLUtil.new
      compIdentifier = @ondemandHelper.compObj.identifier
      
      scopeComps = Set.new
      
      queue = Array.new # Queue<String>
      queue << compIdentifier
      while queue.empty? == false
        compInQueue = queue.shift
        parents = xmlUtil.getParents(compInQueue)
        parents.each{|parent|
          queue << parent
          scopeComps << parent
          }
        
      end
      
      scopeComps << compIdentifier
      
      scopeComps.each{|compName|
          subs = xmlUtil.getChildren(compName)
          
          subs.each{|sub| 
            if !scopeComps.include? sub # scopeComps is set
              # scopeComps << sub
              subs.delete sub
            end
            }
          scope.addComponent(compName,xmlUtil.getParents(compName),subs)
        }
      targetComps = Set.new  
      targetComps << @ondemandHelper.compObj.identifier
      scope.target = targetComps
      
      return scope  
    end
    
    def onDemandIsDone
      puts "setup: called onDemandIsDone, delete status[currentObj]"
      hostComp = @ondemandHelper.compObj.identifier
      
      @ondemandRequestStatus.delete hostComp
      @confirmOndemandStatus.delete hostComp
      
      
    end
    
    private
    # 对于依赖自己的构件，要求进行ondemand setup
    def reqOndemandSetup(currentComp,requestSrcComp) #return bool
      hostComp = currentComp
      targetRef = nil#Set.new
      parentComps = nil#Set.new  
      scope = @depMgr.scope
      puts "setup: scope = #{scope}" # 为啥要写scope，ddm的scope到底怎么计算的？？？？
      if scope == nil
        targetRef = Set.new(depMgr.getStaticDeps) 
        parentComps = Set.new(depMgr.getStaticInDeps)
      else
        targetRef = Set.new(scope.subComponents[hostComp])  
        parentComps = Set.new(scope.parentComponents[hostComp])
      end
      
      reqStatus = {} #Map<string,bool>
      
      if @ondemandRequestStatus[currentComp] != nil
        reqStatus = @ondemandRequestStatus[currentComp]
      else
        reqStatus = {} # map<String,bool>
       
        
        targetRef.each{|subComp|
          if reqStatus[subComp] == nil
            reqStatus[subComp] = false
          end
          }
          
           @ondemandRequestStatus[currentComp] = reqStatus
      end
      
      confirmStatus = {}
      if @confirmOndemandStatus[currentComp] != nil
        confirmStatus = @confirmOndemandStatus[currentComp]
      else
        
        
        
        parentComps.each{|comp|
          # puts "inside : #{comp}"
          if confirmStatus[comp] == nil
            confirmStatus[comp] = false
          end
          }
          
          @confirmOndemandStatus[currentComp] = confirmStatus
      end
      targetRefStr =""
      targetRef.each{|t| targetRefStr += t +","}
      puts "ondemand setup : ***#{hostComp} 's targetRef : #{targetRefStr}"
      
      parentCompsStr = ""
      parentComps.each{|p| parentCompsStr += p+","}
      puts "ondemand setup: ***#{hostComp} 's parents: #{parentCompsStr}"
      #同时，接受本构件所依赖构件发起的ondemand请求 ， 为啥parent是空的？？？
      # wait for other reqOndemandSetup
      receiveReqOndemandSetup(requestSrcComp,hostComp,parentComps)
      
    end
    
    def confirmOndemandSetup(parentComp,currentComp)
      puts "ondemand setup : **** confirmOndemandSetup from #{parentComp} , cur = #{currentComp}"
      
      if @compLifecycleMgr.compStatus == Dea::CompStatus::VALID # what this means ? when did I change it to valid?
        
        puts "ondemand setup : **** component status is valid, return "
        return true
      end
      
      confirmStatus = @confirmOndemandStatus[currentComp]
      
      if confirmStatus != nil && confirmStatus[parentComp] != nil 
        confirmStatus[parentComp] = true
      else
        puts "setup : confirm nil ? #{confirmStatus == nil}"
        puts "setup: confirm[parent] == nil ? #{confirmStatus[parentComp] == nil}"
        puts "ondemand setup : illegal status while confirm ondemand setup"
        return false
      end
      
      isConfirmedAll = true

      synchronize do
          confirmStatus.each{|key,value|
            isConfirmedAll = isConfirmedAll && value
            }
          if isConfirmedAll && @compLifecycleMgr.compStatus == Dea::CompStatus::ONDEMAND
            puts "ondemand setup : confirmOndemandSetup from #{parentComp} ,"+
                  " and confirmed all , trying to change mode to valid"
            # TODO to be tested
            puts "currentComp = #{currentComp}"
              updateMgr = Dea::NodeManager.instance.getUpdateManager(currentComp)
             updateMgr.ondemandSetupIsDone()
            
             sendConfirmOndemandSetup(currentComp)
          else
            puts "setup : confirmOndemandSetup : isConfirmedAll = #{isConfirmedAll}"  
            puts "setup: confirmOndemandSetup: compStatus = #{@compLifecycleMgr.compStatus}"
          end  
      end
      return true  
    end
    
    def onDemandSetup  # private method , return bool
      rtInDeps = @depMgr.getRuntimeInDeps
      rtOutDeps = @depMgr.getRuntimeDeps
      
      txs = @depMgr.getTxs() # Map<string,TransactionContext>
      
      fDeps = Set.new 
      pDeps = Set.new 
      sDeps = Set.new  #static Deps?
      
      curComp = @ondemandHelper.compObj.identifier
      
      targetRef = nil#Set.new#{}
      scope = @depMgr.scope
      
      if scope == nil
        targetRef = Set.new(@depMgr.getStaticDeps)
      else
        targetRef = Set.new(scope.subComponents)
      end
      
      txs.each{|key,txContext|
        rootTx = txContext.getProxyRootTxId(scope)
        
        curTx = txContext.currentTx
        
        if rootTx == nil|| curTx == nil
          puts "!!! ondemand setup : invalid data found while onDemandSetup"
          next
        end
        
        if rootTx != curTx && txContext.eventType == Dea::TxEventType::TransactionEnd
          next
        end
        
        lfe = Dependence.new(Dea::VersionConsistency::FUTURE_DEP,rootTx,curComp,curComp,nil,nil)
        
        lpe = Dependence.new(Dea::VersionConsistency::PAST_DEP,rootTx,curComp,curComp,nil,nil)
        
        rtInDeps << lfe
        rtInDeps << lpe
        
        rtOutDeps << lfe
        rtOutDeps << lpe
        
        if rootTx != curTx
          puts "ondemand setup : current tx is #{curTx}, and root is #{rootTx}"
          next
        end
        
        puts "ondemand setup : curTx is a rootTx"
        
        if txContext.isFakeTx
          next
        end
        fDeps = getFDeps(curComp,rootTx)
        # puts "ondemand setup : fDeps #{fDeps}"
        fDeps.each{|dep|
          
          if !targetRef.include? dep.targetCompObjIdentifier 
                                
            next
          end
          
          dep.tyope = Dea::VersionConsistency::FUTURE_DEP
          dep.rootTx = rootTx
          
          targetComp = dep.targetCompObjIdentifier
          
          subTxStatus = txContext.subTxStatuses
          subComps = txContext.subTxHostComps
          
          subTxID = nil
          subFlag  = false
          subComps.each{|keys,value|
            
            if value == targetComp
              subTxID  = keys
              
              if subTxStatus[subTxID] != Dea::TxEventType::TransactionEnd
                subFlag = true
                break
              end
            end
      
            }
            
            lastUseFlag = true
            
            if subFlag
              isLastUse = true
              txDepMonitor = Dea::NodeManager.instace.getTxDepMonitor(curComp)
              
              isLastUse = txDepMonitor.isLastUse(txContext.currentTx, targetComp,curComp)
              
              lastUseFlag = isLaseUse && lastUseFlag
              
              if isLastUse
                fDeps.delete(dep)
              end
            else
              lastUseFlag = false
            end
          
            # if subTx has already started and also this is not last access . we should create this future dep
            
            if rtOutDeps.include?(dep) == false && lastUseFlag == false
              rtOutDeps << dep
#               TODO testing send message
              # ondeamndComm
              payloadSend = ConsistencyPayloadCreator.createPayload4(dep.srcCompObjIdentifier,
                                               dep.targetCompObjIdentifier,
                                        dep.rootTx, Dea::DepOperationType::NOTIFY_FUTURE_ONDEMAND)
#               ondemandComm.synPost(curComp,dep.targetCompObjIdentifier,"CONSISTENCY","ONDEMAND_MSG",payloadSend)
#               
              depNotifySync(curComp,dep.targetCompObjIdentifier,payloadSend)
            end
          
          
          
          } # end fDeps.each
          
          pDeps = getPDeps(curComp,rootTx)
          
          pDeps.each{|dep|
            
            if !targetRef.include? dep.targetCompObjIdentifier #is a set
              next
            end
            
            dep.type= Dea::VersionConsistency::PAST_DEP
            dep.rootTx = rootTx1
            
            if !rtOutDeps.include? dep
              rtOutDeps << dep
              
              # TODO testing
               payloadSend = ConsistencyPayloadCreator.createPayload4(dep.srcCompObjIdentifier,
                                               dep.targetCompObjIdentifier,
                                        dep.rootTx, Dea::DepOperationType::NOTIFY_PAST_ONDEMAND)
#               ondemandComm.synPost(curComp,dep.targetCompObjIdentifier,"CONSISTENCY","ONDEMAND_MSG",
                depNotifySync(curComp,dep.targetCompObjIdentifier,payloadSend)
            end
              
          } # end pDeps.each
          
          sDeps = getSDeps(curComp,rootTx)
        
          sDeps.each{|dep|
               if !targetRef.include? dep.targetCompObjIdentifier
                 next
               end
               
               dep.rootTx = rootTx
               dep.type = Dea::VersionConsistency::FUTURE_DEP
               
               if !fDeps.include? dep
                 #notify sub future ondemand
                 
                 payloadSend = ConsistencyPayloadCreator.createPayload4(dep.srcCompObjIdentifier,
                                               dep.targetCompObjIdentifier,
                                        dep.rootTx, Dea::DepOperationType::NOTIFY_SUB_FUTURE_ONDEMAND)
#               ondemandComm.synPost(curComp,dep.targetCompObjIdentifier,"CONSISTENCY","ONDEMAND_MSG",payloadSend)
              
                depNotifySync(curComp,dep.targetCompObjIdentifier,payloadSend)
               end
               
               dep.type = Dea::VersionConsistency::PAST_DEP
               
               if !pDeps.include? dep
                 #TODO testing,好像暂时还没遇到？
                 payloadSend = ConsistencyPayloadCreator.createPayload4(dep.srcCompObjIdentifier,
                                               dep.targetCompObjIdentifier,
                                        dep.rootTx, Dea::DepOperationType::NOTIFY_SUB_PAST_ONDEMAND)
#               ondemandComm.synPost(curComp,dep.targetCompObjIdentifier,"CONSISTENCY","ONDEMAND_MSG",payloadSend)
               depNotifySync(curComp,dep.targetCompObjIdentifier)
               end
            }# end sDeps.each
            
        }# end txs.each
        
        return true
    end
    
    def notifyFutureOndemand(dep) #Dependence
      puts "ondemand_setup : notifyFutureOndemand(Dependence deo) with #{dep.to_s}"
      
      rtInDeps = @depMgr.getRuntimeInDeps
      
      rtOutDeps = @depMgr.getRuntimeDeps
      
      curComp = dep.targetCompObjIdentifier
      
      rootTx = dep.rootTx
      scope = @depMgr.scope
      
      targetRef = nil#Set<String>
      
      if scope == nil
        targetRef = Set.new(@depMgr.getStaticDeps)
      else
        targetRef = Set.new(scope.subComponents[curComp])
      end
      
      rtInDeps << dep
      
      targetRef.each{|subComp|
        futureDep = Dependence.new(Dea::VersionConsistency::FUTURE_DEP,rootTx,curComp,subComp,nil,nil)
        
        if !rtOutDeps.include? futureDep
          rtOutDeps << futureDep
          #TODO testing notify future ondemand 
          payloadSend = ConsistencyPayloadCreator.createPayload4(curComp , subComp,rootTx,
                                                 Dea::DepOperationType::NOTIFY_FUTURE_ONDEMAND)
#               ondemandComm.synPost(curComp,subComp,"CONSISTENCY","ONDEMAND_MSG",payloadSend)
          depNotifySync(curComp,subComp,payloadSend)
        end
      }
      
    end
    
    def notifyPastOndemand(dep)
      puts "ondemand_setup: notifyPastOndemand (Dep) with #{dep.to_s}"
      
      rtInDeps = @depMgr.getRuntimeInDeps
      rtOutDeps = @depMgr.getRuntimeDeps
      
      curComp = dep.targetCompObjIdentifier
      rootTx = dep.rootTx
      
      scope = @depMgr.scope
      
      targetRef = nil
      if scope == nil
        targetRef = Set.new(@depMgr.getStaticDeps)
      else
        targetRef = Set.new(scope.subComponents[curComp])
        
      end
      
      rtInDeps << dep
      
      targetRef.each{|subComp|
        pastDep = Dea::Dependence.new(Dea::VersionConsistency::PAST_DEP,rootTx,curComp,subComp,nil,nil)
        
        if !rtOutDeps.include? pastDep
          rtOutDeps << pastDep
          
          #TODO notify past ondemand
           payloadSend = ConsistencyPayloadCreator.createPayload4(curComp ,subComp, 
                                         rootTx, Dea::DepOperationType::NOTIFY_PAST_ONDEMAND)
#               ondemandComm.synPost(curComp,subComp,"CONSISTENCY","ONDEMAND_MSG",payloadSend)
           depNotifySync(curComp,subComp,payloadSend)
        end 
        }
        
      return true
    end
    
    
    
    def notifySubFutureOndemand(dep) #Dependence
      puts "ondemand_setup: notifySubFutureOndemand(Dependence dep) with #{dep.to_s}"
      
      rtInDeps = @depMgr.getRuntimeInDeps
      
      rtOutDeps = @depMgr.getRuntimeDeps
      
      curComp = dep.targetCompObjIdentifier
      
      rootTx = dep.rootTx
      scope = @depMgr.scope
      
      targetRef = nil#Set<String>
      
      fDeps = Set.new
      sDeps = Set.new
      subTx = getHostSubTx(rootTx)
      
      if scope == nil
        targetRef = Set.new(@depMgr.getStaticDeps)
      else
        targetRef = Set.new(scope.subComponents[curComp])
      end
      
   
      fDeps = getFDeps(curComp,subTx)
      
      puts "ondemand : fDeps #{fDeps}"
      fDeps.each{|ose|
        
        if !targetRef.include? ose.targetCompObjIdentifier
          next
        end
        futureDep = Dependence.new(Dea::VersionConsistency::FUTURE_DEP,rootTx,curComp,
                                   ose.targetCompObjIdentifier,nil,nil)
        
        if !rtOutDeps.include? futureDep
          rtOutDeps << futureDep
          #TODO testing notify future ondemand
          payloadSend = ConsistencyPayloadCreator.createPayload4(curComp ,
                                               ose.targetCompObjIdentifier,
                                         rootTx, Dea::DepOperationType::NOTIFY_FUTURE_ONDEMAND)
#               ondemandComm.synPost(curComp,dep.targetCompObjIdentifier,"CONSISTENCY","ONDEMAND_MSG",payloadSend)
         depNotifySync(curComp,ose.targetCompObjIdentifier,payloadSend)
        end
      }
      
      sDeps = getSDeps(curComp,subTx)
      
      puts "ondemand: sDeps #{sDeps}"
      
      sDeps.each{|ose|
        
        if !targetRef.include? ose.targetCompObjIdentifier
          next
        end
        
        if !fDeps.include? ose
           #TODO testing notify sub future ondemand
          payloadSend = ConsistencyPayloadCreator.createPayload4(curComp ,
                                               ose.targetCompObjIdentifier,
                                         rootTx, Dea::DepOperationType::NOTIFY_FUTURE_ONDEMAND)
#               ondemandComm.synPost(curComp,ose.targetCompObjIdentifier,"CONSISTENCY","ONDEMAND_MSG",payloadSend)
          depNotifySync(curComp,ose.targetCompObjIdentifier)
        end
        }
      
    end
    
    def notifySubPastOndemand(dep)
      puts "ondemand_setup : notifySubPastOndemand (Dep) with #{dep.to_s}"
      
      rtInDeps = @depMgr.getRuntimeInDeps
      rtOutDeps = @depMgr.getRuntimeDeps
      
      curComp = dep.targetCompObjIdentifier
      rootTx = dep.rootTx
      subTx = getHostSubTx(rootTx)
      scope = @depMgr.scope
      
      targetRef = nil
      if scope == nil
        targetRef = Set.new(@depMgr.getStaticDeps)
      else
        targetRef = Set.new(scope.subComponents[curComp])       
      end
      
      pDeps =  getPDeps(curComp,subTx)  
      
      pDeps.each{|ose|
        pastDep = Dea::Dependence.new(Dea::VersionConsistency::PAST_DEP,rootTx,curComp,
                                     ose.targetCompObjIdentifier,nil,nil)
        
        if !rtOutDeps.include? pastDep
          rtOutDeps << pastDep
          
          #TODO testing notify sub past ondemand
          payloadSend = ConsistencyPayloadCreator.createPayload4(curComp ,
                                               ose.targetCompObjIdentifier,
                                         rootTx, Dea::DepOperationType::NOTIFY_PAST_ONDEMAND)
#               ondemandComm.synPost(curComp,ose.targetCompObjIdentifier,"CONSISTENCY","ONDEMAND_MSG",payloadSend)
          depNotifySync(curComp,ose.targetCompObjIdentifier,payloadSend)
        end 
        }
      sDeps = getSDeps(curComp,subTx)
      
      sDeps.each{|ose|
        
        if !targetRef.include? ose.targetCompObjIdentifier
           #TODO notify sub , future ondemand
          payloadSend = ConsistencyPayloadCreator.createPayload4(curComp ,
                                               ose.targetCompObjIdentifier,
                                        rootTx, Dea::DepOperationType::NOTIFY_SUB_PAST_ONDEMAND)
          depNotifySync(curComp,ose.targetCompObjIdentifier,payloadSend)                              
#               ondemandComm.synPost(curComp,dep.targetCompObjIdentifier,"CONSISTENCY","ONDEMAND_MSG",payloadSend)
        end
        }  
      return true
    end
    
    
    def receiveReqOndemandSetup(requestSrcComp,currentComp, parentComponents) #String,String,Set<String>
      puts "ondemand_setup : requestSrcComp = #{requestSrcComp},currentComp = #{currentComp}"
      puts "ondemand_setup: ondemandRequestStatus #{@ondemandRequestStatus}"
      @ondemandRequestStatus.each{|key,value|
        
        puts "request Status , key = #{key} ,value = #{value}"
        }
        
      reqStatus = @ondemandRequestStatus[currentComp]
      
      if reqStatus[requestSrcComp] != nil
        reqStatus[requestSrcComp] = true
      else
        puts "!!!ondemandRequestStatus doesn't contain #{requestSrcComp}"
      end
      
      ondemandRequestStr = "currentComp: #{currentComp}, OndemandRequestStatus:"
      reqStatus.each{|key,value|
        ondemandRequestStr += "\n\t " + key + ","+ value.to_s
        }
        
      puts "ondemand setup: str #{ondemandRequestStr}"  
      
      # to judge whether current component has received reqOndemandSetup(...) from
      # every in-scope outgoing static edge
      isReceivedAll = true
      
      reqStatus.each{|key,value|
        puts "setup : received method, key = #{key}, value = #{value}"
        isReceivedAll = isReceivedAll && value
        }
        
      synchronize do 
        
          if isReceivedAll && @compLifecycleMgr.compStatus == Dea::CompStatus::NORMAL
                puts "demand_setup : received reqOndemandSetup (...) from #{requestSrcComp}"
                puts "demand_setup : Received all reqOndemandSetup(...) , trying to change mode to ondemand"
                
                if @depMgr.getRuntimeDeps.size != 0
                  @depMgr.getRuntimeDeps.clear
                end
                
                if @depMgr.getRuntimeInDeps.size != 0
                  @depMgr.getRuntimeInDeps.clear
                  
                end
                
                # change current componentStatus to ondemand
                # test
                updateMgr = Dea::NodeManager.instance.getUpdateManager(currentComp)
                
                updateMgr.ondemandSetting()
                # send reqOndemandSetup(...) to parent Comps
                sendReqOndemandSetup(parentComponents,currentComp) #为什么有时候parent是空的？？？
                # onDemandSetup
                
                ondemandSyncMonitor = @compLifecycleMgr.compObj.ondemandSyncMonitor
                
                ondemandSyncMonitor.synchronize do
                  if @compLifecycleMgr.compStatus == Dea::CompStatus::ONDEMAND
                    allTxs = @depMgr.getTxs() # Map<String,TransactionContext>
                    
                    txStr =""
                    allTxs.each{|key,txCtx|
                      
                      txStr += txCtx.to_s + "\n"
                      }
                    puts "ondemand_setup: TxRegistry:\n #{txStr}"
                    
                    puts "ondemand_setup : synchronizing for method onDemandSetup() in VC_ondemandSetup"
                    
                    onDemandSetup()
                  end
                end
               
               isConfirmedAll = true
               confirmStatus = @confirmOndemandStatus[currentComp]
               
               if confirmStatus == nil
                  puts "setup: currentComp : #{currentComp} , requestSrcComp : #{srcSrcComp}"
                      +",compStatus : #{@compLifecycleMgr.compStatus} , confirmStatus : #{confirmStatus} "  
                  
               end
               
               confirmStatus.each{|key,value|
                 isConfirmedAll = isConfirmedAll && value
                 }
               
               puts "setup !!! isConfirmedAll = #{isConfirmedAll}"  
               confirmStatusStr = "currentComp: #{currentComp} , confirmOndemandStatusStr:"
               
               confirmStatus.each{|key,value|
                 confirmStatusStr += "\t #{key}:#{value}"
                 }
               puts confirmStatusStr
               
               if isConfirmedAll
                  if @compLifecycleMgr.compStatus == Dea::CompStatus::VALID
                    
                    puts "ondemand : confirmed all and component status is valid"
                    return              
                  end
                  
                  puts "ondemand: confirmed from all parent components in receivedReqOndemandSetup(...)"
                  
                  puts "ondemand :trying to change mode to valid"
                  
                  updateMgr.ondemandSetupIsDone()
                  
                  sendConfirmOndemandSetup(currentComp)
               end  
        else
          puts "!!! : setup : not received all or comp.status != normal"
          puts "setup : isReceivedAll= #{isReceivedAll} , compStatus = #{@compLifecycleMgr.compStatus}"   
        end
      end   
    end
    
    
    def sendReqOndemandSetup(parentComps,hostComp)
      
      puts "ondemand_setup : currentCompStatus = ondemand,before send req ondemand to parent component"
      
      str ="currentComp:#{hostComp} ,  sendReqOndemandSetup(...) to parentComponents "
      
      parentComps.each{|parent|str += parent +","}
      
      puts "ondemand_setup : #{str} "
            
      parentComps.each{|parent|
        #  send , need testing
        payloadSend = Dea::DepPayload::OPERATION_TYPE + ":" + Dea::DepOperationType::REQ_ONDEMAND_SETUP + "," +
            Dea::DepPayload::SRC_COMPONENT + ":" + hostComp +"," + 
            Dea::DepPayload::TARGET_COMPONENT + ":" + parent +"," +
            Dea::DepPayload::SCOPE + ":" + @depMgr.scope.to_s 
                                                   
         comm =  @xmlUtil.getAllComponentsComm
         ip =  "192.168.12.34"
         port =  comm[parent]
         
         puts "#{ip},#{port}"
  #                ip,port,srcIdentifier,targetIdentifier,protocol,msgType,payload,commType
         Dea::ASynCommClient.sendMsg(ip,port,hostComp,parent,
                                          "CONSISTENCY","ONDEMAND_MSG",payloadSend,"Async")
        }
      
      return true
    end
    
    def depNotifySync(hostComp,comp,payloadSend)
         puts "ondemand : called dep notify service sync client"
         comm =  @xmlUtil.getAllComponentsComm
         # puts "comm"
         ip =  "192.168.12.34"
         port =  comm[comp]
         
         puts "#{ip},#{port}"
  #               paras=  ip,port,srcIdentifier,targetIdentifier,protocol,msgType,payload,commType
         Dea::SynCommClient.sendMsg(ip,port,hostComp,comp,
                                          "CONSISTENCY",MsgType::ONDEMAND_MSG,payloadSend,"Sync")
    end
    
    def depNotifyAsync(hostComp,comp,payloadSend)
         puts "ondemand : called dep notify service async "
         comm =  @xmlUtil.getAllComponentsComm
         # puts "comm"
         ip =  "192.168.12.34"
         port =  comm[comp]
         
         puts "#{ip},#{port}"
  #               paras=  ip,port,srcIdentifier,targetIdentifier,protocol,msgType,payload,commType
         Dea::ASynCommClient.sendMsg(ip,port,hostComp,comp,
                                          "CONSISTENCY",MsgType::ONDEMAND_MSG,payloadSend,"Async")
    end
    
    def sendConfirmOndemandSetup(hostComp)
      
      targetRef = nil#Set<>
      
      scope = @depMgr.scope
      
      if scope == nil
        targetRef = Set.new(@depMgr.getStaticDeps)
      else
        targetRef = Set.new(scope.subComponents[hostComp])
      end
      
      str ="ondenad_setup : sendConfirmOnDemandSetup(...) to sub components :"
      
      targetRef.each{|comp| str += comp}
      
      puts "ondemand_setup : sendConfirmOndemandSetup : #{str} "
      
      #TODO send ayncPost need testing
      targetRef.each{|subComp|
         payloadSend =  Dea::DepPayload::OPERATION_TYPE + ":" + Dea::DepOperationType::CONFIRM_ONDEMAND_SETUP +
                        "," + Dea::DepPayload::SRC_COMPONENT + ":" + hostComp + 
                        "," + Dea::DepPayload::TARGET_COMPONENT + ":" + subComp
         ip =  "192.168.12.34"
          comm =  @xmlUtil.getAllComponentsComm
         port =  comm[subComp]               
         Dea::ASynCommClient.sendMsg(ip,port,hostComp,subComp,"CONSISTENCY","ONDEMAND_MSG",payloadSend,"Async")   
        }
       end
    
    def getFDeps(curComp,txID) #txID may be a sub tx
      result = Set.new #{skipList<Dependence>}
      
      futureC = Set.new
      txs = @depMgr.getTxs() #Map<String,TransactionContext>
      
      rootTx = nil
      
      if txID != nil
        # read tx dependencies from TxRegistry
        txs.each{|key,ctx|
          if ctx.getProxyRootTxId(@depMgr.scope) == txID || ctx.currentTx == txID
            if @txDepRegistry.getLocalDep(ctx.currentTx).futureComponents != nil ||  @txDepRegistry.getLocalDep(ctx.currentTx).futureComponents.size!=0
              rootTx = ctx.getProxyRootTxId(@depMgr.scope)
               
              @txDepRegistry.getLocalDep(ctx.currentTx).futureComponents.each{|f| futureC << f}
            end
          end
          
          }
      else
        puts "setup : in getFDeps : ondemand: no local subTx running ..." 
        
        scope = @depMgr.scope
        
        if scope == nil
          
          @depMgr.getStaticDeps.each{|s| futureC << s}
        else
          
          scope.subComponents[curComp].each{|sub| futureC << sub}
        end   
               
      end
      
       futureC.each{|comp|
          
          dep = Dea::Dependence.new(Dea::VersionConsistency::FUTURE_DEP, rootTx,curComp,comp,nil,nil)
          result << dep
          }
        str=""  
        result.each{|dep| str += dep.to_s + "\n" }  
        return result  
        
    end
    
    
    
    
    def getPDeps(curComp,txID)
      
      result = Set.new# <Dependence>
      
      pastC = Set.new # <String>
      
      txs = @depMgr.getTxs #Hash<id,txContext>
      rootTx = nil
      # read tx deps from TxRegistry
      
      txs.each{|id,ctx| # TxContext
        
        if ctx.getProxyRootTxId(@depMgr.scope) == txID || ctx.currentTx == txID
          if @txDepRegistry.getLocalDep(ctx.currentTx).pastComponents != nil || @txDepRegistry.getLocalDep(ctx.currentTx).pastComponents.size !=0 
            rootTx = ctx.getProxyRootTxId(@depMgr.scope)
            # pastC = Set.new(
            @txDepRegistry.getLocalDep(ctx.currentTx).pastComponents.each{|p| pastC << p}
          end
        end
        
        }
        str = ""
        pastC.each{|comp|
          dep = Dea::Dependence.new(Dea::VersionConsistency::PAST_DEP,rootTx,curComp,comp,nil,nil)
          result << dep
          str += dep.to_s + "\n"
          }
        puts "ondemand : in getPDeps(...), size = #{result.size} , for rootTx = #{str}"  
        return result
    end
    
    
    def getSDeps(hostComp, txID)
      result = Set.new
      ongoingC = Set.new
      
      txs = @depMgr.getTxs()
      
      rootTx = nil
      
      txs.each{|key,ctx|
        
        if ctx.getProxyRootTxId(@depMgr.scope) == txID || ctx.currentTx == txID
          if ctx.subTxHostComps == nil
            next
          end
          
          ctx.subTxStatuses.each{|subTxID,subTxStatus|
            if !subTxStatus == Dea::TxEventType::TransactionEnd
              ongoingC << ctx.subTxHostComps[subTxID]
            end
            
            }
        end
        } 
      str =""
      ongoingC.each{|comp|
        dep = Dea::Dependence.new(Dea::VersionConsistency::FUTURE_DEP)
        result << dep
        str += dep.to_s+"\n"
        } 
        
      puts "ondemand : in getSdeps(...) size = #{result.size} , for root = #{rootTx} , #{str}"  
      return result 
    end
    
    def getHostSubTx(rootTx)
      txs = @depMgr.getTxs()
      subTx = nil
      txs.each{|currentTx,ctx|
        
        if ctx.isFakeTx
          next
        end
        
        if ctx.getProxyRootTxId(@depMgr.scope) == rootTx || ctx.eventType != Dea::TxEventType::TransactionEnd
          subTx = currentTx
        end
        }
        
      puts "getHostSubTx(#{rootTx}) = #{subTx}"  
      
      return subTx
    end
    
    
    
    
    
    
    
    
    
    
  end
end