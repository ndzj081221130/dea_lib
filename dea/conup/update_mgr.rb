# coding: UTF-8
#conup-extension
require "steno"
require "steno/core_ext"
require "monitor"
require_relative "./buffer_event_type"
require_relative "./component"
require_relative "./comp_lifecycle_mgr"
require_relative "./dynamic_dep_mgr"
require_relative "./comp_updator"
require_relative "./ondemand_setup_helper"
require_relative "./dynamic_update_context"
require_relative "./msg_type"
require_relative "./update_context_payload_resolver"
require_relative "./comp_status"
require_relative "./waiting_freeness_strategy"
require_relative "./blocking_freeness_strategy"
require_relative "./node_mgr"
require_relative "./delegate_router_client"
module Dea
  # update manager is used to execute the real update operation which is delegated from 
  # CompLifecycleMgr
  
  class UpdateManager < Monitor 
    attr_accessor :compLifecycleMgr
    
    attr_accessor :compObj
    attr_accessor :compUpdator
    
    attr_accessor :depMgr
    
    attr_accessor :isUpdated
    
    attr_accessor :ondemandSetupHelper
    
    attr_accessor :updateCtx #DynamicUpdateContext
    
    attr_accessor :bufferEventType #BUFFEREventType.Normal
    
    attr_accessor :instance
    
    def initialize(comp) #ComponentObject
       puts "update_mgr : comp =  #{comp}"
       @compObj = comp
       compIdentifier = comp.identifier
       @instance = nil # actually，每次初始化update mgr时，后面都会紧跟着一句对instance的赋值 
       @compUpdator = Dea::CompUpdator.new
       # @compLifecycleMgr = Dea::CompLifecycleManager.instance(comp) # not nil ,not new
       # @depMgr = Dea::DynamicDepManager.instance(compIdentifier)
       #不是通过单例获取，而是通过nodemgr.getUpdateManager时，set
       super()
    end 
    
    
    def attemptToUpdate
      validToFreeSyncMonitor = @compObj.validToFreeSyncMonitor
      validToFreeSyncMonitor.synchronize do
        if @compLifecycleMgr.compStatus == Dea::CompStatus::VALID && @updateCtx != nil && @updateCtx.isLoaded
          if !@updateCtx.isOldRootTxsInitiated
            puts "update_mgr: initOldRootTxs()"
            initOldRootTxs()
          end
          
          freenessConf = @compObj.freenessConf
          if freenessConf == "blocking_strategy"
            freeness = Dea::BlockingFreenessStrategy.new( @compLifecycleMgr)
          else
            freeness = Dea::WaitingFreenessStrategy.new(@compLifecycleMgr)
          end
          if freeness.isReadyForUpdate(@compObj.identifier)
            puts "update_mgr: achieve Free"
            achieveFree()
          else
            puts "update_mgr : freeness not ready"
          end
        else
                     
          puts "update_mgr: status = #{@compLifecycleMgr.compStatus} , #{@updateCtx} , isLoaded #{@updateCtx.isLoaded}"
        end
      end
      
      updatingSyncMonitor = @compObj.updatingSyncMonitor
      updatingSyncMonitor.synchronize do 
        if @compLifecycleMgr.compStatus == Dea::CompStatus::FREE
          puts "update_mgr: inside updatingMonitor "
          executeUpdate()
          cleanUpdate()
        else
          puts "inside updatingMonitor else : #{@compLifecycleMgr.compStatus}"
        end
      end
    end 
    
    def achieveFree
      validToFreeSyncMonitor = @compObj.validToFreeSyncMonitor
      validCondition = @compObj.validCondition
      validToFreeSyncMonitor.synchronize do
           compStatus = @compLifecycleMgr.compStatus
           puts "updateMgr : in achieveFree: CompStatus= #{compStatus}"
           
           if compStatus == Dea::CompStatus::VALID #|| compStatus == Dea::CompStatus::FREE
             @compLifecycleMgr.transitToFree
             @bufferEventType = Dea::BufferEventType::EXEUPDATE
             notifyInterceptors(@bufferEventType)
             puts "*** component has achieved free , now notify all ****"
             # java calls validToFreeSyncMonitor.notifyAll() , 
             # if I do nothing here ,will there be a dead lock??? of course there will!
             validCondition.signal()
             # should I call validToFreeSyncMonitor.signal ?  cause signal is call when we have a new_cond
             # valid_cond = validToFreeSyncMonitor.new_cond
             # valid_cond.wait_while {num.empty?}
             # valid_cond.signal
                                                                                                                                                                                                                    
           end
      end
    end
    
    def checkFreeness(hostComp)
      validToFreeSyncMonitor = @compObj.validToFreeSyncMonitor
      
      validToFreeSyncMonitor.synchronize do
        if isDynamicUpdateRqstRCVD() && @updateCtx.isOldRootTxsInitiated()
          if @compLifecycleMgr.compStatus == Dea::CompStatus::VALID
            attemptToUpdate()
          end
        end
      end 
    end
    
    
    def cleanUpdate
      #TODO 
      compIdentifier = @compObj.identifier
      puts "update_mgr : *** before set to new version"
      
      
       @compUpdator.finalizeOld(compIdentifier,@updateCtx.oldVerClass,@updateCtx.newVerClass,@instance)
       # puts "a"
       @compUpdator.initNewVersion(compIdentifier,@updateCtx.newVerClass)
       # puts "aa"
       @compUpdator.cleanUpdate(compIdentifier) 
       # puts "af"
       @compUpdator = CompUpdator.new()
       # node.getOndemandSetupHelper(name)
       
       node = Dea::NodeManager.instance
       
       node.ondemandHelpers.delete compIdentifier
     
       
       puts "update_mgr: cleanUpdate: have set to new version"
       puts "finish update and clean up is done!"
       
       updatingSyncMonitor = @compObj.updatingSyncMonitor
       updatingCondition = @compObj.updatingCondition
       
       updatingSyncMonitor.synchronize do
         puts "updatingSyncMonitor同步块内"
         @compLifecycleMgr.transitToNormal()
         @bufferEventType = Dea::BufferEventType::NORMAL
         notifyInterceptors(@bufferEventType)
         updatingCondition.signal
           
         
       end
       
       @depMgr.dynamicUpdateIsDone()
       
       @updateCtx = nil # TODO added by zhang
       
       # instance = @compLifecycleMgr.instance
       # version = @compObj.componentVersion + "1"
       # algconf = @compObj.algorithmConf
       # freeConf = @compObj.freenessConf
       # deps = @compObj.staticDeps
       # indeps = @compObj.staticInDeps
       # implType = @compObj.implType
#        
       # newComp = Dea::ComponentObject.new(compIdentifier,version,algconf,freeConf,deps,indeps,implType)
       # node.compObjects.delete compIdentifier
       # node.addComponentObject(compIdentifier,newComp) 
       # puts newComp
        
    end
    
    def executeUpdate
      compIdentifier = ""
      synchronize do
        if isUpdated
          puts "updateMgr: warning !!! duplicated extecuteUpdate, return directly"
          return
        end
        
        isUpdated=true
        compIdentifier = @compObj.identifier
        @compLifecycleMgr.transitToUpdating()
        
      end
      # update , this is done when valid
      @compUpdator.executeUpdate(compIdentifier,@instance)
    end
    
    def initOldRootTxs
      if !@updateCtx.isOldRootTxsInitiated()
        
        @updateCtx.algorithmOldRootTxs = @depMgr.getAlgorithmOldVersionRootTxs()
        
        if @instance
          puts "updateMgr.instance不为空,向router注册oldRootTxs"
          instance.oldRootTxs = @updateCtx.algorithmOldRootTxs
          DelegateRouterClient.notify_router(@instance)
        end
        puts "#{@compObj.identifier}.update_mgr:通过vc调用getAlgorithmOldRootTxs:" + 
                   " #{@updateCtx.algorithmOldRootTxs().size()} , #{updateCtx.algorithmOldRootTxs().to_a}"
      end
    end
    
    def isDynamicUpdateRqstRCVD
      return @updateCtx!= nil && @updateCtx.isLoaded
    end
    
    private
   def manageDep(reqObj)
     manageResult = @depMgr.manageDependencePayload(reqObj.payload)
     return "manageDepResult:#{manageResult}"    
   end 
    
    def manageOndemand(reqObj)
      ondemandResult = false
      ondemandResult = @ondemandSetupHelper.ondemandSetup3(reqObj.srcIdentifier,reqObj.protocol,reqObj.payload)
      return "ondemandResult:#{ondemandResult}"
    end
    
    def manageRemoteConf(reqObj) #Requestobject
      # puts "updateMgr： manageRemoteConf : "     result = false
      payload = reqObj.payload
      
      payloadResolver = Dea::UpdateContextPayloadResolver.new(payload)
      opType = payloadResolver.operation
      puts "#{@compObj.identifier}.updateMgr: optype = #{opType}"  
      compIdentifier = payloadResolver.getParameter(Dea::UpdateContextPayload::COMP_IDENTIFIER)
      if opType == Dea::UpdateOperationType::UPDATE
        #  get the new version of hello component
        # what should we do in DEA?只需要在baseDir传入新版本的代码的位置即可
        baseDir = payloadResolver.getParameter(Dea::UpdateContextPayload::BASE_DIR)
        classFilePath = payloadResolver.getParameter(Dea::UpdateContextPayload::CLASS_FILE_PATH)
        contributionUri = payloadResolver.getParameter(Dea::UpdateContextPayload::CONTRIBUTION_URI)
        compositeUri = payloadResolver.getParameter(Dea::UpdateContextPayload::COMPOSITE_URI)
        scope = payloadResolver.getParameter(Dea::UpdateContextPayload::SCOPE)
        puts "scope = #{scope}"
        result = update(baseDir,classFilePath,contributionUri,compositeUri,compIdentifier,scope)
        
      elsif opType == Dea::UpdateOperationType::ONDEMAND
       
        scope = Dea::Scope.inverse(payloadResolver.getParameter(Dea::UpdateContextPayload::SCOPE))        
        result = @ondemandSetupHelper.ondemandSetupScope(scope)
        puts  "ondemand result = #{result}" # here return le
      elsif opType == Dea::UpdateOperationType::QUERY
        
      end
      
      return "updateResult:" + result.to_s
    end
    
    
    
    def manageExp(reqObj)
      paylpad = reqObj.payload
      
      updateContextPayloadResolver = Dea::UpdateContextPayloadResolver.new(payload)
      updateOperationType = updateContextPayloadResolver.operation
      
      if updateOperationType == Dea::UpdateOperationType::NOTIFY_UPDATE_IS_DONE_EXP
        puts "coordination receive NOTIFY_UPDATE_IS_DONE_EXP"
      elsif updateOperationType == Dea::UpdateOperationType::GET_EXECUTION_RECORDER
        return "update_mgr : action_"
      end
      
      return "default message"
    end
    
     def notifyInterceptors(eventType)
      puts "update manager : notify interceptors" #TODO what to notify?
    end
    
    public
    
    def processMsg(reqObj)
      msgType = reqObj.msgType
      
      if msgType == Dea::MsgType::DEPENDENCE_MSG
        puts "update_mgr : process dependece msg"
        return manageDep(reqObj)
      elsif msgType == Dea::MsgType::ONDEMAND_MSG
        return manageOndemand(reqObj)
      elsif msgType == Dea::MsgType::REMOTE_CONF_MSG
        return manageRemoteConf(reqObj)
      elsif msgType == Dea::MsgType::EXPERIMENT_MSG
        return manageExp(reqObj)
      else
        puts "updateMgr: unknown msg type"
        return nil        
      end
    end
    
    def update(baseDir,classFilePath,contributionURI,compositeURI,compIdentifier,scope)
      
      synchronize do
        if @updateCtx != nil && @updateCtx.isLoaded
          puts "updateMgr: warning duplicated update request!!!"
          return true
        end
        
        isUpdated= false
        
        @compUpdator.initUpdator(baseDir,classFilePath,contributionURI,compositeURI,compIdentifier)
        @compObj.updateIsReceived# 这里将component的@isTargetComp设为true
      end
      
      if @compLifecycleMgr.compStatus == Dea::CompStatus::NORMAL
        comp = Dea::NodeManager.instance.getComponentObject(compIdentifier)
        ondemandHelper = Dea::NodeManager.instance.getOndemandSetupHelper(compIdentifier)
        puts "update_mgr: before ondemandSetupScope"
        ondemandHelper.ondemandSetupScope(scope)
        
        puts "update_mgr: after ondemandHelper"
      end
      
       attemptUpdateThread = Thread.new(self,@compLifecycleMgr) do |updateMgr,compLifeMgr|
         # waiting while on demand setup
        # updateMgr = self
        # compLifeMgr = @compLifecycleMgr
        # puts "here is a thread !!! attemptUpdateThread"
        ondemandSyncMonitor = compLifeMgr.compObj.ondemandSyncMonitor
        ondemandCondition = compLifeMgr.compObj.ondemandCondition
        
        ondemandSyncMonitor.synchronize do # dead lock ???
          puts "update_mgr: in ondemandMonitor , before depMgr.isOndemandSetupRequired"
          
          compStatus = compLifeMgr.compStatus
          
          if compStatus == Dea::CompStatus::NORMAL || compStatus == Dea::CompStatus::ONDEMAND
            puts "update_mgr: ------in update:    ondemandSyncMonitor.wait(); -----"
            puts "update_mgr : status = #{compStatus}"
            ondemandCondition.wait#   need testing , dead lock ??? 开个多线程，妥妥的
            puts "update_mgr : wait condition satisfied"
          else
            puts "update_mgr : update in ondemandSync, in else : compStatus =  #{compStatus}"  
          end
                 
        end # end of monitor
        
        validToFreeSyncMonitor = compLifeMgr.compObj.validToFreeSyncMonitor
        validCondition = compLifeMgr.compObj.validCondition
        validToFreeSyncMonitor.synchronize do
          # puts "update_mgr : inside validMonitor"
          updateCtx = updateMgr.updateCtx #这个被加锁了？？？
          if compLifeMgr.compStatus == Dea::CompStatus::VALID && updateMgr.isDynamicUpdateRqstRCVD
            puts "update_mgr : compstatus == valid && isDynamicUpdateRqstRVCD == true"
            flag = @updateCtx.isOldRootTxsInitiated()
            puts "flag =  #{flag}"
            if !flag  
              puts "update_mgr : initOldRootTxs()"
              updateMgr.initOldRootTxs()
              puts "update_mgr: after updatMgr.initOldRootTxs()"
            else
              puts "update_mgr : in else"
            end
            
            # freenesConf = compLifeMgr.compObj.freenessConf 
            #好像阻塞在这里了？？？？为什么？？？？ 这里还是在多线程里面的
            # puts freenessConf #这一句？？？因为这里去获取了compObj，我估计因为comp是不是被锁住了？？？
            # if freenessConf == "blocking_strategy"
              freeness = Dea::BlockingFreenessStrategy.new(@compLifecycleMgr)
            # else
              # freeness = Dea::WaitingFreenessStrategy.new(@compLifecycleMgr)
            # end
            
            if freeness.isReadyForUpdate(compLifeMgr.compObj.identifier)
              puts "update_mgr: need updateMgr.achiveFree"
              updateMgr.achieveFree()
            else
              
              puts "update_mgr: not ready for update yet, suspend AttempToUpdateThread"
#               need testing throughly
              validCondition.wait()
              puts "update_mgr:wait satified"
            end
          end
          
        end
        
        puts "update_mgr : before updateMgr attemptToUpdate()"
        updateMgr.attemptToUpdate()
        
      end # end of thread.new
     
      # attemptUpdateThread.join , here i did not use a thread , but can add here
      return true
    end
    
    def removeAlgorithmOldRootTx(rootTxId)
      if isDynamicUpdateRqstRCVD() && @updateCtx.isOldRootTxsInitiated()
        @updateCtx.removeAlgorithmOldRootTx(rootTxId)
        
        if @instance
          puts "updateMgr.instance不为空,向router注册删除后的oldRootTxs"
          instance.oldRootTxs = @updateCtx.algorithmOldRootTxs
          DelegateRouterClient.notify_router(@instance)
        end
        
        puts "updateMgr: removeOldRootTx(ALG && BUFFER) txID: #{rootTxId}"        
        if @compLifecycleMgr.compStatus == Dea::CompStatus::VALID
          attemptToUpdate()
        end
      else
        flag = isDynamicUpdateRqstRCVD()
        flag_i = false
        if @updateCtx
          flag_i = @updateCtx.isOldRootTxsInitiated()
        end
        puts "update_mgr : in removeAlgorithmOldRootTx, isDynamic #{flag} , isOldRootInit #{flag_i}"
      end 
    end
    
    def ondemandSetupIsDone
      puts "update_mgr : ondemandSetupIsDone"
      ondemandSyncMonitor = @compObj.ondemandSyncMonitor
      ondemandCondition = @compObj.ondemandCondition
      
      compStatus = @compLifecycleMgr.compStatus
      
      ondemandSyncMonitor.synchronize do
        
        if compStatus == Dea::CompStatus::ONDEMAND
          
          @compLifecycleMgr.transitToValid
          
          if @compObj.isTargetComp
            @bufferEventType = Dea::BufferEventType::VALIDTOFREE
            if !@updateCtx.isOldRootTxsInitiated
              initOldRootTxs()
            end
          else
            
            @bufferEventType = Dea::BufferEventType::WAITFORREMOTEUPDATE
              
          end
          

            notifyInterceptors(@bufferEventType)
            #   here may be not the same one ? 不是，一个component对应一个helper
             
            @ondemandSetupHelper.ondemandIsDone()
            #  ondemandSyncMonitor.notifyAll
            # what should ruby code do to notify all that is waiting or ??? use condition wait
            #这里，通知ondemandCondition？ 对的
            ondemandCondition.signal() 
            
            puts "updateMgr: **** #{@compObj.identifier} ondemand setup is done , now notify all ondemandSyncMonitor***"
            
            if @compObj.isTargetComp
              puts "update_mgr.ondemandIsDone : #{@compObj} is target component"
              @depMgr.ondemandSetupIsDone()
            end
        end 
      end
    end
    
    
    
   
    
    def remoteDynamicUpdateIsDone
      waitingRemoteCompUpdateDoneMonitor = @compObj.waitingRemoteCompUpdateDoneMonitor
#                                                  @waitingRemoteCompUpdateMonitor @watingRemoteCompUpdateMonitor
      waitingCondition = @compObj.waitingCondition
      
      waitingRemoteCompUpdateDoneMonitor.synchronize do
        
        compStatus = @compLifecycleMgr.compStatus
        
        if compStatus == Dea::CompStatus::VALID
          @compLifecycleMgr.transitToNormal()
          @bufferEventType = Dea::BufferEventType::NORMAL
          
          notifyInterceptors(@bufferEventType)
          
          compIdentifier = @compObj.identifier
          
          puts "update_mgr: in remoteDynamicUpdateisDone :#{compIdentifier} remote update is done , CompStatus #{compStatus}, now notify all"
          waitingCondition.signal
          #waitingRemoteCompUpdateDoneMonitor.notifyAll
        end
        
        
      end
      
      
    end
    
    def ondemandSetting
         #ondemandSetting
        ondemandSyncMonitor = @compObj.ondemandSyncMonitor
        ondemandSyncMonitor.synchronize do 
          
          compStatus = @compLifecycleMgr.compStatus
          
          if compStatus == Dea::CompStatus::NORMAL
            @compLifecycleMgr.transitToOndemand
            
            @bufferEventType = Dea::BufferEventType::ONDEMAND
#             TODO notify do what ???
            notifyInterceptors(@bufferEventyType)
          end
          
        end
        
        
      end
    
    
  end
end