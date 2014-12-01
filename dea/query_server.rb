require 'eventmachine'
require "steno"
require "steno/core_ext"
require 'json'
require "set"

require_relative "./conup/tx_dep_monitor"
require_relative "./conup/tx_event_type"
require_relative "./conup/client"
require_relative "./conup/client_sync"
require_relative "./conup/query_type"
require_relative "./conup/tx_lifecycle_mgr"
require_relative "./conup/invocation_context"
require_relative "./conup/request_object"
require_relative "./conup/update_mgr"
require_relative "./conup/comp_status"
require_relative "./conup/comp_lifecycle_mgr"
require_relative "./conup/buffer_event_type"
require_relative "./conup/node_mgr"
module Dea
  class QueryServer
    # this is used for collect tx data from clients and collect data from other dea collect_servers
    class Echo < EM::Connection
      attr_accessor :configCollect
      attr_accessor :configPort
      attr_accessor :bootstrap
      
      def initialize(config,port,boot)
        @configCollect = config
        @configPort = port
        @bootstrap = boot
      end
      
      def receive_data(data)
        

        puts "Query.Server port : #{@configPort  } received data:"
         

        handle = data[2,data.length] # there are two unknown chars
        puts handle
        puts
        @json = JSON::parse(handle)
        
        msgType = @json["msgType"]
        
        if msgType != nil #这里是接受到请求,  
          puts "query_server : from remote end,type = #{msgType}"
          
          if msgType == QueryType::Components
             
             nodeMgr = NodeManager.instance
             componentName = @json["componentName"]
             comps = nodeMgr.getComponentsViaName(componentName)
             
             result = comps.to_a.to_json
          elsif msgType == QueryType::Ports
            nodeMgr = NodeManager.instance
            ports = nodeMgr.getAllPorts
            result = ports.to_a.to_json
         
          elsif msgType == QueryType::Instances
             
            result = bootstrap.instance_registry.instances.to_json
          elsif msgType == QueryType::Instance
            new_name = @json["componentName"] 
            flag = @bootstrap.instance_registry.has_instances_for_application(new_name)
            result = flag.to_json
          elsif msgType == QueryType::NodeManager
            nodeMgr = NodeManager.instance
            result = nodeMgr #消息传递的是string啊，该对象能序列化？
            
          elsif msgType == QueryType::ComponentLifecycleMgr
            nodeMgr = NodeManager.instance
            name = @json["componentName"]
            port = @json["componentVersionPort"]
            key = name +":" + port
            lifecycleMgr = nodeMgr.getCompLifecycleManager(key)
            result = lifecycleMgr
          elsif msgType == QueryType::TxDepMonitor
            nodeMgr = NodeManager.instance
            name = @json["componentName"]
            port = @json["componentVersionPort"]
            key = name +":" + port
            result = nodeMgr.getTxDepMonitor(key)
          elsif msgType == QueryType::TxLifecycleMgr
            nodeMgr = NodeManager.instance
            name = @json["componentName"]
            port = @json["componentVersionPort"]
            key = name +":" + port
            result = nodeMgr.getTxLifecycleManager(key)
          elsif msgType == QueryType::DepMgr
            nodeMgr = NodeManager.instance
            name = @json["componentName"]
            port = @json["componentVersionPort"]
            key = name +":" + port
            result = nodeMgr.getDynamicDepManager(key)             
          elsif msgType == QueryType::UpdateMgr
            nodeMgr = NodeManager.instance
            name = @json["componentName"]
            port = @json["componentVersionPort"]
            key = name +":" + port
            result = nodeMgr.getUpdateManager(key)
          elsif msgType == QueryType::OndemandHelper
            nodeMgr = NodeManager.instance
            name = @json["componentName"]
            port = @json["componentVersionPort"]
            key = name +":" + port
            result = nodeMgr.getOndemandSetupHelper(key)
          elsif msgType == QueryType::DeleteComponent  
            nodeMgr = NodeManager.instance
            componentName = @json["componentName"]
            result = nodeMgr.removeComponentsViaName(componentName)
          elsif msgType == QueryType::UpdateComponentNormal
            nodeMgr = NodeManager.instance
            componentName = @json["componentName"]
            componentVersionPort = @json["componentVersionPort"]
            key = componentName+":"+componentVersionPort
            lifecycleMgr = nodeMgr.getCompLifecycleManager(key)
            if lifecycleMgr != nil
              lifecycleMgr.transitToNormal()
              result = "update to normal succeed"
            else
              result = "no such component: #{componentName} , #{componentVersionPort}"
            end
          elsif msgType == QueryType::UpdateComponentValid
            nodeMgr = NodeManager.instance
            componentName = @json["componentName"]
            componentVersionPort = @json["componentVersionPort"]
            key = componentName+":"+componentVersionPort
            lifecycleMgr = nodeMgr.getCompLifecycleManager(key)
            if lifecycleMgr != nil
              lifecycleMgr.transitToValid
              result = "update to valid succeed"
            else
              result = "no such component: #{componentName} , #{componentVersionPort}"
            end
          elsif msgType == QueryType::UpdateComponentFree
            nodeMgr = NodeManager.instance
            componentName = @json["componentName"]
            componentVersionPort = @json["componentVersionPort"]
            key = componentName+":"+componentVersionPort
            lifecycleMgr = nodeMgr.getCompLifecycleManager(key)
            if lifecycleMgr != nil
              lifecycleMgr.transitToFree
              result = "update to free succeed"
            else
              result = "no such component: #{componentName} , #{componentVersionPort}"
            end
          elsif msgType == QueryType::UpdateComponentOndemand
            nodeMgr = NodeManager.instance
            componentName = @json["componentName"]
            componentVersionPort = @json["componentVersionPort"]
            key = componentName+":"+componentVersionPort
            lifecycleMgr = nodeMgr.getCompLifecycleManager(key)
            if lifecycleMgr != nil
              lifecycleMgr.transitToOndemand
              result = "update to ondemand succeed"
            else
              result = "no such component: #{componentName} , #{componentVersionPort}"
            end
          elsif msgType == QueryType::DrawRegistryTable
            nodeMgr = NodeManager.instance
            compObjects = nodeMgr.compObjects

            result = "Name     | Port    | CompLifecycleMgr  |  TxLifecycleMgr  | DDM     |  TxDepMonitor  |  UpdateMgr   |\n "
           
            compObjects.each{|compKey,componentObject|
              
              name = componentObject.identifier
              port = componentObject.componentVersionPort
              
              key = name +":" + port.to_s
              
              compLifeMgr = nodeMgr.getComponentObject(key)
              txMgr = nodeMgr.getTxLifecycleManager(key)
                 
              ddm = nodeMgr.getDynamicDepManager(key)
            
              ondemandHelper = nodeMgr.getOndemandSetupHelper(key)
              txDepMonitor = nodeMgr.getTxDepMonitor(key)
              updateMgr = nodeMgr.getUpdateManager(key)
              result +=  "#{name}  #{port}   #{compLifeMgr} #{txMgr} #{ddm} #{txDepMonitor} #{updateMgr} \n" 
            }    
              
          elsif msgType == QueryType::AddComponent
            nodeMgr = NodeManager.instance
            componentName = @json["componentName"]
            
            componentVersionPort = @json["componentVersionPort"]
            key = componentName+":"+componentVersionPort    
              
            alg="consistency"
            freeConf="concurrent_version_for_freeness"
            deps = Set.new #children#
            
            indeps = Set.new #parents
            indeps << "ProcComponent"
            indeps << "PortalComponent"            
            implType="Java_POJO"
              
            comp = Dea::ComponentObject.new(componentName,componentVersionPort,alg,freeConf,deps,indeps,implType)
            nodeMgr.addComponentObject(key,comp)
            id = key
            
            compLifeMgr = Dea::CompLifecycleManager.new(comp,nil)
            
            nodeMgr.setCompLifecycleManager(key,compLifeMgr)
            txLifecycleMgr = Dea::TxLifecycleManager.new(comp)
            nodeMgr.setTxLifecycleManager(id,txLifecycleMgr)
             
            #nodeMgr.getDynamicDepManager(id)

            #nodeMgr.getOndemandSetupHelper(id)
            
            txDepMonitor = Dea::TxDepMonitor.new(comp)
            nodeMgr.setTxDepMonitor(id,txDepMonitor)

            result = true
          else
            result = "unknown msgType #{msgType}"
          end 
          
          puts "query result = #{result}"
          if result == nil
            result = "nil obj" #这里如果返回空，或者返回空串，会导致消息的滞留or something
          end
          send_data(result)
          
        else
          
          puts "well, how should I handle this ? "  
        end
 
      end
    end

    attr_reader :ip
    attr_reader :port
    attr_accessor :config
    attr_accessor :bootstrap
    
    def initialize(ip, port,config,bootstrap)
      @ip = ip
      @port = port   
      @config = config  
      @bootstrap = bootstrap
    end

    def start
      EM.run do
      #puts "test"
        EM.start_server(@ip,@port,Echo,@config,@port ,@bootstrap)

        puts "start finished #{@port}"
        logger.info "Connecting query   server on #{@port}"
      end

    end

  end
end
