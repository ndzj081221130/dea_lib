#UTF-8
require 'singleton'
require 'monitor'
require 'set'
require_relative "./ondemand_setup_helper"
require_relative "./ondemand_setup"
require 'monitor'
# require
module Dea
  class NodeManager  
      
    
    include Singleton
    
    attr_accessor :syncMonitor
    attr_accessor :pushMonitor 
    attr_accessor :ondemandHelpers 
    attr_accessor :compObjects # Hash < id:port, ComponentObject >
    # attr_accessor :instance
    
    def initialize
      @compObjects = {}
      @depMgrs = {}
      @ondemandHelpers = {}
      @txLifecycleMgrs = {}
      @txDepMonitors = {}
      @compLifecycleMgrs = {}
      @updateMgrs = {}
      @syncMonitor="1"
      @syncMonitor.extend(MonitorMixin)
      
      @pushMonitor ="2"
      @pushMonitor.extend(MonitorMixin)
    end
    
    def removeComponentsViaName(name)
      puts "Called removeComponentsViaName #{name}"
      @compObjects.delete_if{|key,instance| instance.identifier == name} 
      @compObjects 
    end
    
    def getComponentsViaName(name)     
      
      # puts "called " 
      resultPorts = Set.new
       @compObjects.each{|key,comp|
        # puts comp
         if comp.identifier == name
           
           resultPorts << comp.componentVersionPort
         end
         }
      resultPorts
    end
    
    def getKeysViaName(name)      
      resultKeys = Set.new
       @compObjects.each{|key,comp|
         #puts comp
         if comp.identifier == name
           
           resultKeys << name +":" + comp.componentVersionPort 
         end
         }
      resultKeys
    end
    
    def getAllPorts
      
      resultPorts = Set.new
      
       @compObjects.each{|comp|
         
           resultPorts << comp.componentVersionPort
           
         }
      resultPorts
    end
    
    
    def getComponentObject(identifier) #TODO changed ,testing , here identifier = name +":" + port
      #identifier  use to be string , here we need it be int(port)
      # or use string+port?
      #puts "identifier #{identifier}"
      #puts @compObjects
      return @compObjects[identifier]
    end
    
    def addComponentObject(identifier,compObj)#TODO changed ,testing
      # puts identifier
      # puts compObj
      @compObjects[identifier] = compObj
      # puts @compObjects
    end
    
    def removeCompObjectViaId(identifier) 
      @compObjects.delete identifier
      @depMgrs.delete identifier
      @ondemandHelpers.delete identifier
    end
    
    def removeCompObject(compObject) #TODO changed ,testing
      key = compObject.identifier  + ":" + compObj.componentVersionPort.to_s 
      removeCompObjectViaId(key)
    end
    
    #   getCompLifecycleManager
    def getCompLifecycleManager(compIdentifier) #here id = name+port
      compObj = nil
      compLifecycleMgr = nil
      @syncMonitor.synchronize do
        compObj = getComponentObject(compIdentifier)
        if compObj == nil
          puts "node_mgr: getCompLifecycleMgr: compObj == nil for #{compIdentifier}"
          return  nil
        end
        
        if !@compLifecycleMgrs.include? compObj
          raise RuntimeError.new , "CompLifecycleMgr not found."
        else
          compLifecycleMgr = @compLifecycleMgrs[compObj]
        end
        
      end
      
      compLifecycleMgr
    end
    
    def setCompLifecycleManager(identifier,compLifecycleMgr)
      compObj = nil
      @syncMonitor.synchronize do 
        compObj = getComponentObject(identifier)
        if !@compLifecycleMgrs.include? compObj
          @compLifecycleMgrs[compObj] = compLifecycleMgr
          return true
        else
          return false
        end        
      end
    end
    
    def getTxLifecycleManager(identifier)
      txLifecycleMgr = nil
      @syncMonitor.synchronize do
        compObj = getComponentObject(identifier)
        if compObj ==nil
          puts "comp nil ? "
          return nil
        end
        
        if !@txLifecycleMgrs.include? compObj
          raise RuntimeError.new,"TxLifecycleMgr not found."
        else
          txLifecycleMgr = @txLifecycleMgrs[compObj]
        end
      end
      txLifecycleMgr
    end
    
    def setTxLifecycleManager(identifier,txLifecycleMgr)
      @syncMonitor.synchronize do
        compObj = getComponentObject(identifier)
        if !@txLifecycleMgrs.include? compObj
          @txLifecycleMgrs[compObj] = txLifecycleMgr
          return true
        else
          return false
        end
      end
    end
    
    def getDynamicDepManager(identifier)
      depMgr = nil
      @syncMonitor.synchronize do
        compObj = getComponentObject(identifier)
        if compObj == nil
          return nil
        end
        if !@depMgrs.include? compObj
          depMgr = Dea::DynamicDepManager.new(compObj)
          depMgr.compLifecycleMgr=@compLifecycleMgrs[compObj]
          depMgr.txLifecycleMgr=@txLifecycleMgrs[compObj]
          @depMgrs[compObj] = depMgr
          
        else
          depMgr = @depMgrs[compObj]
        end
      end
    end
    
    def getOndemandSetupHelper(identifier)
      helper = nil
      
      @syncMonitor.synchronize do
        compObj = getComponentObject(identifier)
        
        if compObj == nil
          return nil
        end
        
        if !@ondemandHelpers.include? compObj
          helper = Dea::OndemandSetupHelper.new(compObj)
          
          ondemandSetup = Dea::VCOndemandSetup.new(compObj)
          helper.ondemandSetup = ondemandSetup
          helper.depMgr = getDynamicDepManager(identifier)
          helper.ondemandSetup.depMgr = getDynamicDepManager(identifier)
          
          puts "depMgr.nil? #{helper.ondemandSetup.depMgr == nil}"
          helper.compLifecycleMgr= getCompLifecycleManager(identifier)
          helper.ondemandSetup.compLifecycleMgr = getCompLifecycleManager(identifier)
          @ondemandHelpers[compObj] = helper
        else
          helper = @ondemandHelpers[compObj]
        end
        
      end
      helper
    end
    
    def getTxDepMonitor(identifier)
      txDepMonitor = nil
      @syncMonitor.synchronize do
        compObj = getComponentObject(identifier)
        if compObj == nil
          return nil
        end
        if !@txDepMonitors.include? compObj
          puts "TxDepMonitor not found."
          puts @txDepMonitors
          raise RuntimeError.new,"TxDepMonitor not found."
        else
          txDepMonitor = @txDepMonitors[compObj]
          ondemandHelper = @ondemandHelpers[compObj]
          ondemandHelper.ondemandSetup.txDepRegistry = txDepMonitor.txDepRegistry
        end
      end
      txDepMonitor
    end
    
    def setTxDepMonitor(identifier,txDepMonitor)
      @syncMonitor.synchronize do
        compObj = getComponentObject(identifier)
        if !@txDepMonitors.include? compObj
          @txDepMonitors[compObj] = txDepMonitor
          return true
        else
          return false
        end
      end
    end
     
    def getUpdateManager(identifierKey)
      updateMgr = nil
      @syncMonitor.synchronize do  
        compObj = getComponentObject(identifierKey)
        if compObj == nil
          #puts "nodeMgr: in getUpdateMgr, compObj = nil for #{identifierKey}"
          return nil 
        end
        
        if !@updateMgrs.include? compObj
          updateMgr = Dea::UpdateManager.new(compObj)
          # updateMgr.instance = @instance        
          updateMgr.depMgr= @depMgrs[compObj]
          updateMgr.ondemandSetupHelper= @ondemandHelpers[compObj]
          updateMgr.compLifecycleMgr= @compLifecycleMgrs[compObj]
           @updateMgrs[compObj] = updateMgr
         else
           updateMgr = @updateMgrs[compObj]
        end
      end
      
      updateMgr
    end
    
     
  end
end