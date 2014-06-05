# coding: UTF-8
#conup-core
require "steno"
require "steno/core_ext"
require_relative "./ondemand_setup"

module Dea
  
  class OndemandSetupHelper
    
    attr_accessor :compLifecycleMgr
    attr_accessor :depMgr
    attr_accessor :ondemandSetup
    attr_accessor :compObj #ComponentObject
    
    attr_accessor :isOndemandRqstRcvd
    
    
    def initialize(comp) #ComponentObject
      @compObj = comp
      puts "ondemand_setup_helper: #{comp}"
      @ondemandSetup = Dea::VCOndemandSetup.new(comp)
      @ondemandSetup.ondemandHelper= self # we need to set helper here
      
      
    end
    
    def ondemandSetupScope(scope)
      if @isOndemandRqstRcvd
        puts "helper: duplicated ondemand setup from component #{@compObj.identifier}"
        return true
      end
      
      puts "ondemand_setup_helper: ondemandSetupScope : ---------------received ondemand setup request."
      @isOndemandRqstRcvd = true
      puts "ondemand_setup_helper: scope = #{scope}"
      @ondemandSetup.ondemandHelper = self
      #TODO start a thread for calling 
      @ondemandSetup.ondemand(scope)
    end
    
    def ondemandSetup3(srcIdentifier,protocol,payload)
      @ondemandSetup.ondemandHelper = self
      #TODO call PeerCommOndemandThread run 
      @ondemandSetup.ondemandSetup(srcIdentifier,protocol,payload)
    end
    
    def isOndemandDone
      return @ondemandSetup.isOndemandDone      
    end
    
    def ondemandIsDone
      isOndemandRqstRcvd = false
      @ondemandSetup.onDemandIsDone()
    end
    
    
  end
end