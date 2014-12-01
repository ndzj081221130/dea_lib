# UTF-8

require "../conup/dynamic_dep_mgr"
require "../conup/node_mgr"

id = "ProcComponent"
version="1.0"
alg="consistency"
freeConf="concurrent_version_for_freeness"
deps = Array.new #children#
#deps << "AuthComponent"
deps << "DBComponent"

indeps = Array.new #parents
indeps << "PortalComponent"
implType="Java_POJO"
compProc = Dea::ComponentObject.new(id,version,alg,freeConf,deps,indeps,implType)

# ddm = Dea::DynamicDepManager::new(compProc)

# payload =""
# ddm.manageDependencePayload(payload)

#ddm.manageDependence() # this is private method , so needn't test
node1 = Dea::NodeManager.instance
node2 = Dea::NodeManager.instance
node1.addComponentObject(id,compProc)

comp = node2.getComponentObject(id)
puts comp
compAuthLifecycleMgr = Dea::CompLifecycleManager.new(compProc)
node2.setCompLifecycleManager(id,compAuthLifecycleMgr)

compLifecycleMgr = node1.getCompLifecycleManager(id)
puts compLifecycleMgr

puts "-----------test txLifecycleMgr"

txLifecycleMgr = Dea::TxLifecycleManager.new(compProc)
node1.setTxLifecycleManager(id,txLifecycleMgr)

puts node2.getTxLifecycleManager(id)

puts "-------------test ddm"

ddm= node1.getDynamicDepManager(id)
 ddm.ondemandSetupIsDone
#TODO need more tests

