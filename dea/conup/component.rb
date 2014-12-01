# coding: UTF-8
#conup-spi
require "steno"
require "steno/core_ext"
require "monitor"
require 'logger'
module Dea
  class ComponentObject
    attr_accessor :identifier #String, name
    attr_accessor :componentVersionPort #String
    
    attr_accessor :algorithmConf #String
    attr_accessor :freenessConf #string
    attr_accessor :staticDeps #set<String>
    attr_accessor :staticInDeps #set<string>
    
    attr_accessor :implType # String
    attr_accessor :isTargetComp #boolean
    
    attr_accessor :ondemandSyncMonitor #sync object
    attr_accessor :ondemandCondition
    
    attr_accessor :validToFreeSyncMonitor#sync object
    attr_accessor :validCondition
    
    attr_accessor :updatingSyncMonitor #sync object
    attr_accessor :updatingCondition
    
    attr_accessor :waitingRemoteCompUpdateDoneMonitor #sync object
    attr_accessor :waitingCondition
    
    attr_accessor :freezeSyncMonitor #sync object
    attr_accessor :freezeCondition
    
    attr_accessor :logger
    def initialize(id,versionPort,algconf,freeConf, deps, indeps,impltype)
      puts "called component initialized!!!"
      logger.debug "comp initialize"
      @identifier = id
      @componentVersionPort = versionPort
      @algorithmConf = algconf
      @freenessConf = freeConf
      @staticDeps = deps
      @staticInDeps = indeps
       
      @implType = impltype
      @isTargetComp = false
      
      @ondemandSyncMonitor="1"
      @ondemandSyncMonitor.extend(MonitorMixin)
      @ondemandCondition = @ondemandSyncMonitor.new_cond
      
      @validToFreeSyncMonitor="2"
      @validToFreeSyncMonitor.extend(MonitorMixin)
      @validCondition = @validToFreeSyncMonitor.new_cond
      
      @updatingSyncMonitor="3"
      @updatingSyncMonitor.extend(MonitorMixin)
      @updatingCondition = @updatingSyncMonitor.new_cond
      
      @waitingRemoteCompUpdateDoneMonitor="4"
      @waitingRemoteCompUpdateDoneMonitor.extend(MonitorMixin)
      @waitingCondition = @waitingRemoteCompUpdateDoneMonitor.new_cond
      
      @freezeSyncMonitor="5"
      @freezeSyncMonitor.extend(MonitorMixin)
      @freezeCondition = @freezeSyncMonitor.new_cond
    end
    
    def logger
      @logger ||= Logger.new("/vagrant/logs/comp.log")
    end

    def logger=(logger)
      @logger = logger
    end 
    
    def updateIsReceived
      @isTargetComp= true
    end
    
    def updateIsDone
      @isTargetComp= false
    end
    
    def to_s
      str = "component [id: #{@identifier} , version:#{@componentVersionPort}, staticDeps:"
      if @staticDeps
      @staticDeps.each{|dep|
        str += dep +"/"
        }
      end
      str += ",staticInDeps:"
      if @staticInDeps
      @staticInDeps.each{|dep|
        str += dep+"/"
        # puts "dep : #{dep}" 
        
        }  
      end
      str += ", isTargetComp:#{@isTargetComp}]"
      str  
    end
    
  end
end
