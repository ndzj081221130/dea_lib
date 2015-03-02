require_relative "../conup/node_mgr"
require_relative "../conup/comp_lifecycle_mgr"
require_relative "../conup/component"
require "set"
require_relative "../conup/tx_lifecycle_mgr"
require_relative "../conup/tx_dep_monitor"
require_relative "../conup/datamodel/query_type"
require_relative "../conup/comm/client_sync_response"

#nodeMgr = Dea::NodeManager.instance

msg = {}
msg["msgType"] = Dea::QueryType::NodeManager  
ip = "192.168.12.34"
client4 = Dea::ClientSyncResponse.new(ip,"8701",msg.to_json)

nodeMgr =  client4.response


compObjects = nodeMgr.compObjects

puts "Name     | Port    | CompLifecycleMgr  |  TxLifecycleMgr  | DDM     |  TxDepMonitor  |  UpdateMgr   | "
compObjects.each{|componentObject|
  
  name = componentObject.identifier
  port = componentObject.componentVersionPort
  
  key = name +":" + port.to_s
  
  # compLifeMgr = nodeMgr.getComponentObject(key)
  # txMgr = nodeMgr.getTxLifecycleManager(key)
#      
  # ddm = nodeMgr.getDynamicDepManager(key)
# 
  # ondemandHelper = nodeMgr.getOndemandSetupHelper(key)
  # txDepMointor = nodeMgr.getTxDepMonitor(key)
  # updateMgr = nodeMgr.getUpdateManager(key)

  puts "#{name}  #{port}  "###{compLifeMgr} #{txMgr} #{ddm} #{txDepMonitor} #{updateMgr}" 
}
