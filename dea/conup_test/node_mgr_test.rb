#UTF-8

require_relative "../conup/node_mgr"
require_relative "../conup/comp_lifecycle_mgr"
require_relative "../conup/component"
require "set"
require_relative "../conup/tx_lifecycle_mgr"
require_relative "../conup/tx_dep_monitor"


id = "AuthComponent"
version ="1.0"
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

node1.addComponentObject("AuthComponent",compAuth)


node2 = Dea::NodeManager.instance
comp = node2.getComponentObject("AuthComponent")
puts comp

compAuthLifecycleMgr = Dea::CompLifecycleManager.new(compAuth)
node2.setCompLifecycleManager(id,compAuthLifecycleMgr)

compLifecycleMgr = node1.getCompLifecycleManager("AuthComponent")
puts compLifecycleMgr

puts "-----------test txLifecycleMgr"

txLifecycleMgr = Dea::TxLifecycleManager.new(compAuth)
node1.setTxLifecycleManager(id,txLifecycleMgr)

puts node2.getTxLifecycleManager(id)

puts "-------------test ddm"

puts node1.getDynamicDepManager(id)

puts "---------test helper"

puts node2.getOndemandSetupHelper(id)

puts "---------test txDepMonitor"
txDepMonitor = Dea::TxDepMonitor.new(compAuth)
puts node2.setTxDepMonitor(id,txDepMonitor)
puts node1.getTxDepMonitor(id)

puts "-------test updateMgr"


puts node1.getUpdateManager(id)



