#UTF-8
require 'singleton'
require 'monitor'
require_relative "./ondemand_setup_helper"
require_relative "./ondemand_setup"

# require
module Dea
  class NodeManager  
      
    
    include Singleton
    
    attr_accessor :syncMonitor
     
    attr_accessor :ondemandHelpers 
    attr_accessor :compObjects
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
    end
    
    def getComponentObject(identifier)
      #puts @compObjects
      return @compObjects[identifier]
    end
    
    def addComponentObject(identifier,compObj)
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
    
    def removeCompObject(compObject)
      removeCompObjectViaId(compObject.identifier)
    end
    #   getCompLifecycleManager
    def getCompLifecycleManager(compIdentifier)
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
    
    #{"HelloworldComponent"=>component [id: HelloworldComponent , version:1.0, staticDeps:,staticInDeps:CallComponent/, isTargetComp:false]}
# nodeMgr: in getUpdateMgr, compObj = nil for component [id: HelloworldComponent , version:1.0, staticDeps:,staticInDeps:CallComponent/, isTargetComp:false]

    def getUpdateManager(identifier)
      updateMgr = nil
      @syncMonitor.synchronize do  
        compObj = getComponentObject(identifier)
        if compObj == nil
          puts "nodeMgr: in getUpdateMgr, compObj = nil for #{identifier}"
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