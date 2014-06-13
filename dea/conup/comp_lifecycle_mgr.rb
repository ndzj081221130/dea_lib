# coding: UTF-8
# conup-tuscany-extension
#require "eventmachine"
require "steno"
require "steno/core_ext"
require_relative "./comp_status"
require_relative "./dynamic_dep_mgr"
require "monitor"
require_relative "./node_mgr"
require_relative "../nats"
module Dea
  class CompLifecycleManager
    
    attr_accessor :compObj # Object
    attr_accessor :compStatus
    attr_accessor :instance
    
    def initialize(comp,instance) # comp is ComponentObject
      @compObj = comp
      @compStatus =  CompStatus::NORMAL
      @compStatus.extend(MonitorMixin)
      @instance = instance
      
      @keyGet = @compObj.identifier + ":" + @compObj.componentVersionPort.to_s
    end
     
    
    def stop(comp)
      return false
    end
    
    def isReadyForUpdate #  to be test thoroughly
      # nodemanger.getDynamicDepMgr
      #ddm is  , and needs to setAlgorith and setCompObj
      ddm = NodeManager.instance.getDynamicDepManager(@keyGet)
      puts "comp_lifecycle_mgr: ddm.isReady? #{ddm.isReadyForUpdate}"
      return (@compStatus  == CompStatus::VALID && ddm.isReadyForUpdate) || @compStatus == CompStatus::FREE  
    end
    
    def transitToNormal
      #synchronize(compstatus) #TODO 为什么这里要加锁？？？在哪里释放呢？？？
      puts "compLifecycleMgr: transitToNormal"
      # @compStatus.synchronize do # TODO 这里我没加锁，会不会有问题？？？
        puts "inside compStatus同步块内" # 为什么没进来？？？先将锁去掉
        if @compStatus == CompStatus::VALID || @compStatus == CompStatus::UPDATING
          @compStatus = CompStatus::NORMAL
        else
          puts "error!!!comp_lifecycle_mgr:compStatus = #{@compStatus}, cannot transit to normal"
        end
      # end
      
      # 这里也要修改instance状态
      if  @instance
       @instance.stats = CompStatus::NORMAL
       notify_router(@instance)
       
     end
    end
    
    def notify_router(instance)
      raw_data = "{\"id\":\"b9bdc46ab4582344e17cc0fb9cb2fa33\",\"hosts\":[\"10.0.2.15\"]}"
      subject = "router.start"
      respond_to = nil
      message = Dea::Nats::Message.decode(instance.bootstrap.nats, subject, raw_data, respond_to)
      instance.bootstrap.handle_router_start(message)
      # "{\"id\":\"b9bdc46ab4582344e17cc0fb9cb2fa33\",\"hosts\":[\"10.0.2.15\"]},respond_to = 
    end
    
    def transitToOndemand
      #这个也要修改instance状态
      @compStatus = CompStatus::ONDEMAND
      if @instance
        @instance.stats = CompStatus::ONDEMAND
        notify_router(@instance)
      end
    end
    
    def transitToValid
      # transitToValid 这个是要，修改instance的状态的
      puts "compLifecycleMgr trainsit to valid"
      @compStatus = CompStatus::VALID
       if @instance != nil
          @instance.stats = CompStatus::VALID
          notify_router(@instance)
      end
    end
    
    def transitToUpdating
      @compStatus = CompStatus::UPDATING
     # 要，修改instance的状态的
      if @instance != nil
         @instance.stats = CompStatus::UPDATING
         notify_router(@instance)
     end
    end
    
    def transitToFree
      @compStatus = CompStatus::FREE
      #要，修改instance的状态的
       if  @instance
          @instance.stats = CompStatus::FREE
          notify_router(@instance)
      end
    end
    
    def isNormal
      return @compStatus  == CompStatus::NORMAL
    end
    
    def isOndemandSetting
      return @compStatus  == CompStatus::ONDEMAND
    end
    
    def isValid
      return @compStatus  == CompStatus::VALID
    end
   
    def isFree
      return @compStatus  == CompStatus::FREE 
    end
    
    
    
    
  end
  
end