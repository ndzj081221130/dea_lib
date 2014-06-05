# UTF-8

require "../conup/comp_lifecycle_mgr"
require "../conup/version_consistency"
id = "AuthComponent"
version ="1.0"
alg="consistency"
freeConf="concurrent_version_for_freeness"
deps = Array.new #children#
indeps = Array.new #parents
indeps << "ProcComponent"
indeps << "PortalComponent"


implType="Java_POJO"
 
compAuth = Dea::ComponentObject.new(id,version,alg,freeConf,deps,indeps,implType)
algorithm = Dea::VersionConsistency.new

# ddm = Dea::DynamicDepManager.new(compAuth)
# ddm.compObj = compAuth
# ddm.algorithm = algorithm
 
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

mgr = Dea::CompLifecycleManager.new(compAuth)

mgr.transitToNormal 

puts mgr.compStatus #NORMAL

mgr.transitToValid
puts "isReadyForUpdate?"

puts mgr.isReadyForUpdate
puts mgr.isNormal #false
puts mgr.isValid #true

mgr.transitToUpdating 
puts mgr.isFree # false

mgr.transitToFree
puts "isReadyForUpdate?"
puts mgr.isReadyForUpdate
puts mgr.isOndemandSetting #false

# mgr.transitTo