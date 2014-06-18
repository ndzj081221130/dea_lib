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
        #send_data(data)

        puts "Query.Server port : #{@configPort  } received data:"
         

        handle = data[2,data.length] # there are two unknown chars
        puts handle
        puts
        @json = JSON::parse(handle)
        
        msgType = @json["msgType"]
        
        if msgType != nil #这里是接受到 请求,  
          puts "query_server : from remote end"
          
          if msgType == QueryType::Components
             
             nodeMgr = NodeManager.instance
             componentName = @json["componentName"]
             ports = nodeMgr.getComponentsViaName(componentName)
             
             result = ports.to_a.to_json
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
          elsif msgType == QueryType::DeleteComponent  
            nodeMgr = NodeManager.instance
            componentName = @json["componentName"]
            result = nodeMgr.removeComponentsViaName(componentName)
          else
            result = ""
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
