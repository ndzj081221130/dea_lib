#UTF-8

require_relative "../conup/node_mgr"
require_relative "../conup/comp_lifecycle_mgr"
require_relative "../conup/component"
require "set"
require_relative "../conup/tx_lifecycle_mgr"
require_relative "../conup/tx_dep_monitor"


id = "AuthComponent"
version ="8000"
alg="consistency"
freeConf="concurrent_version_for_freeness"
deps = Set.new #children#

indeps = Set.new #parents
indeps << "ProcComponent"
indeps << "PortalComponent"


implType="Java_POJO"
 
 compAuth = Dea::ComponentObject.new(id,version,alg,freeConf,deps,indeps,implType)
# 
 puts compAuth
 
node1 = Dea::NodeManager.instance

node1.addComponentObject("AuthComponent:8000",compAuth)


node2 = Dea::NodeManager.instance
comp = node2.getComponentObject("AuthComponent:8000")
puts comp
 

compAuth2 = Dea::ComponentObject.new(id,8100,alg,freeConf,deps,indeps,implType)
node2.addComponentObject("AuthComponent:8100",compAuth2)

compDb = Dea::ComponentObject.new("DBComponent",8200,alg,freeConf,deps,indeps,implType)
node1.addComponentObject("DBComponent:8200" , compDb)
puts node2.compObjects

node1.removeComponentsViaName("AuthComponent")


puts node2.compObjects


# 
# puts "-----------test txLifecycleMgr"
# 
# txLifecycleMgr = Dea::TxLifecycleManager.new(compAuth)
# node1.setTxLifecycleManager(id,txLifecycleMgr)
# 
# puts node2.getTxLifecycleManager(id)
# 
# puts "-------------test ddm"
# 
# puts node1.getDynamicDepManager(id)
# 
# puts "---------test helper"
# 
# puts node2.getOndemandSetupHelper(id)
# 
# puts "---------test txDepMonitor"
# txDepMonitor = Dea::TxDepMonitor.new(compAuth)
# puts node2.setTxDepMonitor(id,txDepMonitor)
# puts node1.getTxDepMonitor(id)
# 
# puts "-------test updateMgr"
# 
# 
# puts node1.getUpdateManager(id)



