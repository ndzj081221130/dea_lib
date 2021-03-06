require 'eventmachine'
require "steno"
require "steno/core_ext"
require 'json'
require "set"
require 'socket' 
require_relative "./conup/tx_dep_monitor"
require_relative "./conup/datamodel/tx_event_type"
require_relative "./conup/comm/client_once"
require_relative "./conup/comm/client_sync"
# require_relative "./conup/client_go_response"
require_relative "./conup/tx_lifecycle_mgr"
require_relative "./conup/invocation_context"
require_relative "./conup/request_object"
require_relative "./conup/update_mgr"
require_relative "./conup/datamodel/comp_status"
require_relative "./conup/comp_lifecycle_mgr"
require_relative "./conup/datamodel/buffer_event_type"
require_relative "./conup/node_mgr"
module Dea
  class MessageServer
    # this is used for collect tx data from clients and collect data from other dea collect_servers
    class Echo < EM::Connection
      attr_accessor :configCollect
      attr_accessor :configPort
      attr_accessor :instance
      
      def initialize(config,port,instance)
        @configCollect = config
        @configPort = port
        @instance = instance
      end
      
       
    
    def handle_remote_msg(message)
      
      begin
        
          json = JSON::parse(message)

          parentPort = json["ParentPort"]
          parentName = json["ParentName"]
          parentTx = json["ParentTx"]
          rootTx = json["RootTx"]
          subPort = json["SubPort"]
          subName = json["SubName"]
          invocationCtx = json["InvocationCtx"] #InvocationCtx
          key = subName + ":" + subPort.to_s
          if rootTx == nil || rootTx == ""
               # puts  "root tx = nil , no need ..."
          else
           #   puts "#{@configPort} proof that I am subComponent"
            #  puts "#{key}.collect_server : i get notify  to cache invocationCtx from router  "
              parentTx =  json["ParentTx"]
              parentC =  json["ParentName"]
              parentPort =  json["ParentPort"]
              rootTx =  json["RootTx"]
           
              target =  json["SubName"] 
              invocationCtxFromHeader =  json["InvocationCtx"]# 空的？？？why？？？
           #   puts "InvocationCtxFrom header #{invocationCtxFromHeader}"
           #    问题 invocationContext中的fakeTx是怎么回事?主要是，call生成一个fakeSubTX，因为此时，call不知道hell的tx
    
            
             name = target
             
             if Dea::NodeManager.instance.getComponentObject(key) == nil
              #    puts "#{key}.collect_server: component.nil #{key} "
                  comp = Dea::ComponentObject.new(target,@configPort,alg,freeConf,deps,indeps,implType)
                 #  一旦建立comp，就要建立一堆东西，否则，会取到空指针的
                              
                  node = Dea::NodeManager.instance
                  
                  node.addComponentObject(key,comp)
                  compLifeMgr = Dea::CompLifecycleManager.new(comp,@instance)
                                    
                  node.setCompLifecycleManager(key,compLifeMgr)
                  
                  txLifecycleMgr = Dea::TxLifecycleManager.new(comp)
                  node.setTxLifecycleManager(key,txLifecycleMgr)
                  
                  txDepMonitor = Dea::TxDepMonitor.new(comp)
                  node.setTxDepMonitor(key,txDepMonitor)
                  
                  depMgr = node.getDynamicDepManager(key)
                  depMgr.txLifecycleMgr= txLifecycleMgr
                  depMgr.compLifecycleMgr= compLifeMgr
                  
                  node.getOndemandSetupHelper(key)
                  updateMgr = node.getUpdateManager(key)
                  updateMgr.instance = @instance
            else
                #puts "#{key}.collect_server , component not nil"
                txLifecycleMgr = Dea::NodeManager.instance.getTxLifecycleManager(key)
            end
            logger = txLifecycleMgr.logger                     
            invocationContext = InvocationContext.getInvocationCtx(invocationCtxFromHeader)
            txLifecycleMgr.notifyCache(invocationContext)
            # 走到这里，显然说明，不是一个根事务
            Dea::NodeManager.instance.getTxLifecycleManager(key).resolveInvocationContext(invocationContext,name)
           
            puts "#{key} get msg from router"  
                    
        end
      
      rescue Exception => e
        # puts "Index Error: #{e} , that means , no root tx"
        return
      end

    end
  
  
      def receive_data(data)
        
        puts "port : #{@configPort  } received data:"
        
        handle = data[2,data.length] # there are two unknown chars
       
        @json = JSON::parse(handle)
        instance_id =  @json["instance_id"]

        version = "1.0"
        alg = "consistency"
        freeConf = @json["freeness"]#""#"concurrent_version_for_freeness"
        if freeConf == nil
          freeConf = "blocking_strategy"
        end
        implType = "Java_POJO"
        deps = Set.new
        indeps = Set.new
        if instance_id != nil
          
         # logger.info "collect_server : id=#{instance_id}"

          transaction_id = @json["transaction_id"]
          eventType = @json["event_type"]

          pasts = @json["PastComps"]
          futures = @json["FutureComps"]
          name = @json["name"]
          #puts "#{name}.collect_server get msg"
          if @configCollect[name] == nil # here we need test!!!
            @configCollect[name] = @configPort
          end
          d = @json["deps"]
          d.each{|dd| deps << dd}

          ind = @json["indeps"]

          ind.each{|i| indeps << i}
          key = name + ":" + @configPort.to_s
          #puts "key = #{key}"
          if Dea::NodeManager.instance.getComponentObject(key) != nil
          #  puts "collect_server called getComponentObject"
            comp = Dea::NodeManager.instance.getComponentObject(key)           
            comp.componentVersionPort = @configPort
            comp.algorithmConf  = alg
            comp.freenessConf = freeConf
            comp.staticDeps = deps
            comp.staticInDeps = indeps
            comp.implType = implType
            
          else
            
           # puts "collect_server : new comp"
            comp  = Dea::ComponentObject.new(name,@configPort,alg,freeConf,deps,indeps,implType)
            node = Dea::NodeManager.instance                      
            node.addComponentObject(key,comp)
            compLifeMgr = Dea::CompLifecycleManager.new(comp,@instance)
            node.setCompLifecycleManager(key,compLifeMgr)
            
            txLifecycleMgr = Dea::TxLifecycleManager.new(comp)
            node.setTxLifecycleManager(key,txLifecycleMgr)
            
            txDepMonitor = Dea::TxDepMonitor.new(comp)
            node.setTxDepMonitor(key,txDepMonitor)
            
            depMgr = node.getDynamicDepManager(key) 
            depMgr.txLifecycleMgr= txLifecycleMgr
            depMgr.compLifecycleMgr= compLifeMgr
            
            node.getOndemandSetupHelper(key)
            
            updateMgr = node.getUpdateManager(key)
            updateMgr.instance = @instance
          end
          
          
          logger = comp.logger
          puts "collect_server : comp = #{comp}"
          # we just set value for component

         
          comp.staticDeps = deps
          comp.staticInDeps = indeps

          txDepMonitor = Dea::NodeManager.instance.getTxDepMonitor(key)
          
          # 
          # if txCtx.getRootTx != nil
          #     txLifecycleMgr.initLocalSubTx(name,subTx,txCtx)
          # end 
          #应该是这样的
          
         
          if eventType == Dea::TxEventType::TransactionStart
              # DEA向Router查询，到本实例的请求，是否是来自某个根事务 
              router_ip = @instance.bootstrap.config["router_ip"]
              router_port = @instance.bootstrap.config["router_port"]
              
              msg = {}
  
              msg["InstanceId"] = @instance.private_instance_id
              ref = msg.to_json      
              puts "#{name} send private_instance_id to router : private_instance_id= #{@instance.private_instance_id}"
              streamSock = TCPSocket.new( "192.168.12.34", 6666 )  
              # router opened a port at 6666 for query_server
              streamSock.write( ref )  
              str = streamSock.recv( 1024 )  
              puts "#{name} get from stream sock #{str}"#   
              streamSock.close  
              
              handle_remote_msg(str)
            
            
          elsif eventType == Dea::TxEventType::TransactionEnd #通知父节点，子事务结束。
              #这里总是可以知道tx_id的吧
              name = @json["name"]
              transaction_id = @json["transaction_id"]
              keyEnd = name + ":" + @configPort.to_s
              txLifecycleMgr = Dea::NodeManager.instance.getTxLifecycleManager(key)
              invocationCtx = txLifecycleMgr.tx_invocation_hash[transaction_id]
                                   
              if invocationCtx == nil || invocationCtx.subTx == nil #&& transaction_id #为啥总有
                puts "collect_server : TxEnd, but i am a root tx , no need notify father"#不需要通知父亲，subTxEnd"
                # txLifecycleMgr.endLocalSubTx()
                #^_^，这里调用endLocal
              # elsif invocationCtx.subTx != nil && invocationCtx.hostComp == invocationCtx.subComp
               #                 
             
                send_data("no need call ")
                close_connection_after_writing
              else
                puts "#{name}.collect : if sub tx ends , first call txLifecycleMgr.endLocal"
                #"如果sub tx 结束 ,首先调用自己的endLocalSubTx"
                # assert subComp == hostComp
                hostComp = name
                puts "#{name}.collect: host = #{  hostComp},sub = {invocationCtx.subComp}"
                puts "#{name}.collect :subtx = #{invocationCtx.subTx} , this should be a  fake"
                proxyRootTxId = txLifecycleMgr.endLocalSubTx( hostComp,invocationCtx.subTx)
                puts "#{name}.collect_server: sub tx ended , notify parent"#子事务结束，通知父节点"
                puts "#{name}.collect: invocation : #{invocationCtx}"
                
                hostComp = name
                
                parentComp = invocationCtx.parentComp
                msg = {}
                msg["notify_sub_end"] = "notify_sub_end"
                msg["subComp"] = name
                msg["subTx"] = invocationCtx.subTx
                msg["parentComp"] = invocationCtx.parentComp
                msg["rootTx"] = invocationCtx.rootTx
                parentComp = invocationCtx.parentComp
                msg["invocation_ctx"] = invocationCtx.to_s
                msg["proxy_root_tx_id"] = proxyRootTxId
                @xmlUtil = Dea::XMLUtil.new
                comm =  @xmlUtil.getAllComponentsComm
                puts "collect_server: comm #{comm}"
                ip =  "192.168.12.34"
                port =  comm[parentComp]
         
                client = Dea::ClientSync.new( ip, port,msg.to_json) # need confirm ???
                
                txLifecycleMgr.tx_invocation_hash.delete transaction_id
                send_data("sub #{name} get confirm from parent #{parentComp}")
                close_connection_after_writing
              end
          end
          
          rootTx = txDepMonitor.notify(eventType,transaction_id, futures,pasts) #通知事务依赖监听器
          if eventType == Dea::TxEventType::TransactionStart
            #{name}.
            puts "collect_server send data back , rootTx = #{rootTx}"
            send_data(rootTx)
             
            close_connection_after_writing # why shutdown?
           
          end
          
          if eventType == Dea::TxEventType::FirstRequestService
            puts "collect_server: notify sub dea  about root tx info "
            #通知调用的构件 ,关于根事务和父事务的信息"
            #这里不仅创建InvocationContext，而且调用startRemoteContext
            
            
            other_dea_port = @json["other_dea_port"]
            other_dea_ip = @json["other_dea_ip"]
            target = @json["target_comp"] #太奇怪了，这里的消息是app代码传来的
            msg = {}
            msg["parentTx"]	= transaction_id #这个是在txStart时，获取的事务id。为什么parentTx和rootTx，相等？？？？
            #事实上，不需要知道parentTx的消息，所以这里有bug，不影响
            msg["parentComponent"] = name
            msg["rootTx"] = transaction_id
            msg["rootComponent"] = 	name # is this right???无需知道rootComponent，不影响
            msg["target_comp"] = target
           # puts "other_dea_ip = #{other_dea_ip}"
            puts "other_dea_port #{other_dea_port}"  
            # 在createInvocation中， 调用startRemoteSubTx方法，
            invocationCtx = Dea::NodeManager.instance.getTxLifecycleManager(key).createInvocation(name,target,txDepMonitor)
            #这里显然应该有subFakeTx了啊                       
            msg["invocation_context"] = invocationCtx
            puts "collect_server : FirstRequest , invocationCtx = #{invocationCtx}" 
            # here ,we need send sync msg
            result = invocationCtx.to_json #msg.to_json 
            
            send_data(result) #DEA将invocationCtx也通知给应用代码？
            close_connection_after_writing # why shutdown?
            
              
            
          elsif eventType == Dea::TxEventType::TransactionEnd #通知父节点，子事务结束。
               
          elsif eventType == Dea::TxEventType::DependencesChanged
             send_data "confirm dependence change" 
             close_connection_after_writing   
          end
      

        elsif @json["msgType"] != nil && @json["msgType"] == "SubNotifyParent" 
            #here 与if instance_id === nil同级
            #这里应该永远不会被调用,这段逻辑被移到,这段应该被删除
            # 通知调用的构件 ,关于根事务和父事务的信息"
            #这里不仅创建InvocationContext，而且调用startRemoteContext
            
            parentPort = @json["ParentPort"]
            parentName = @json["ParentName"]
            parentTx = @json["ParentTx"]
            rootTx = @json["RootTx"]
            subPort = @json["SubPort"]
            subName = @json["SubName"]
          
            other_dea_ip = "192.168.12.34"
            other_dea_port = subPort
            
            
            # puts "#{parentName} : #{parentPort}.stats_collect_server.handle : first get msg from sub, then notify sub tx"                      
            # puts "#{parentName} : #{parentPort}.stats_collect_server.handle: notify sub dea about root tx info "
            #             
            # puts "stats_collect_server.handle other_dea_ip = #{other_dea_ip}"
            # puts "stats_collect_server.handle other_dea_port #{other_dea_port}"  
            
            key = parentName + ":" + parentPort
            comp = Dea::NodeManager.instance.getComponentObject(key)
            puts comp == nil
            
            # 在createInvocation中， 调用parentComp.startRemoteSubTx方法，
            txDepMonitor = Dea::NodeManager.instance.getTxDepMonitor(key)
            #puts txDepMonitor == nil
            invocationCtx = Dea::NodeManager.instance.getTxLifecycleManager(key).createInvocation(parentName,target,txDepMonitor)
             
            #这里显然应该有subFakeTx了啊  
            msg = {}
            msg["parentTx"] =   parentTx                   
            msg["parentComponent"] = parentName
            msg["parentPort"] = parentPort
            msg["rootTx"] = rootTx
            msg["rootComponent"] = ""
            msg["target_comp"] = subName
            msg["invocation_context"] = invocationCtx
            puts "#{key}.collect_server : FirstRequest , invocationCtx = #{invocationCtx}" 
          
            puts "collect_server.handle #{parentName} notify #{other_dea_port} , and get confirm msg"
            
            send_data("#{key} already get msg from sub")
            
            streamSock = TCPSocket.new( "192.168.12.34", subPort )  
            streamSock.write( msg.to_json )  
            str = streamSock.recv( 1024 )  
            puts "#{name} get from stream sock #{str}"  
            streamSock.close 
                
          
        elsif @json["rootTx"] != nil && @json["target_comp"] != nil && @json["invocation_context"] != nil
          #  这里是hello接受到call-dea发来的消息，call通知hello，关于InvocationContxt
          #  this is a sync msg ,so we need reply 
          #  puts "collect_server : i get notify  to cache invocationCtx from parent  "
       

            send_data("#{key} resolve invocationCtx done")
            
        elsif @json["subTx"] != nil #这个条件够不？
          sub = @json["subComp"]
          subTx = @json["subTx"]
          name = @json["parentComp"]
          
          key = name + ":" + @configPort.to_s
          
          puts "#{name}.collect_server :get msg from subComp that subTx ended , thus call endRemoteSubTx" 
          #获得子节点，通知子事务结束，调用

          invocationCtx = InvocationContext.getInvocationCtx(@json["invocation_ctx"]) #invocation_ctx
          #这里的proxy_root_Tx_id是什么？？？
          #果然是proxy_root_tx_id计算 , cal root tx
          proxyRootTxId = @json["proxy_root_tx_id"]
          if sub  != name
            
            txLifecycleMgr = Dea::NodeManager.instance.getTxLifecycleManager(key)
            rootTx = @json["rootTx"]
            puts "#{name}.collect_server : call endRemoteSubTx , key = #{key}"
            if txLifecycleMgr
              txLifecycleMgr.endRemoteSubTx(invocationCtx,proxyRootTxId)
            else
              puts "collect_server : txLifecycleMgr==nil"
            end
          end
          
          send_data("#{name} end remote subTx from #{sub}")
        elsif @json["msgType"] != nil #这里是接受到更新请求, 还有来自hello通知call的消息呢？
          puts "collect_server : from remote conf or msg_dependence"
          request = Dea::RequestObject.new
          request.commType= @json["commType"]
          request.srcIdentifier= @json["srcIdentifier"]
          request.targetIdentifier= @json["targetIdentifier"]
          request.protocol= @json["protocol"]
          request.msgType=@json["msgType"]
          request.payload= @json["payload"]
          id = @json["targetIdentifier"]
          
          # puts "payload = #{request.payload}" 
          # puts "collect_server : conf : #{  id } , port = #{ @configPort.to_s}"
          key = id +":" + @configPort.to_s #  testing
          updateMgr = Dea::NodeManager.instance.getUpdateManager(key) #这里的问题 
          if updateMgr != nil
            updateMgr.instance = @instance#如果不加这一句，真的会出现hello的更新转发到db上？
            result = updateMgr.processMsg(request)
            
            # puts "collect_server : msgType!=nil , result = #{result}"
            # write back response
            send_data(result)
          else
            send_data("no updateMgr @ #{key}")
          end
        elsif @json["operation"] != nil
          
          operation = @json["operation"]
          
          if operation == "STOP"
            send_data("closing #{@configPort}")
            #EM.stop
          else
            puts "operation = #{operation} , not recognized"
          end  
        else
          
          #puts "well, how should I handle this ? "  
          send_data("unknown command")
        end
 
      end
    end

    attr_reader :ip
    attr_reader :port
    attr_accessor :config
    attr_accessor :instance
    
    def initialize(ip, port,config,instance)
      @ip = ip
      @port = port   
      @config = config  
      @instance = instance
    end

    def start
      EM.run do
       
        EM.start_server(@ip,@port,  Echo,@config,@port,@instance)#,bootstrap.instance_registry)

        puts "start finished #{@port}"
        logger.info "Connecting collect stats server on #{@port}"
      end

    end

  end
end
