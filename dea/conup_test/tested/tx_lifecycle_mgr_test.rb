# UTF-8

require_relative "../conup/tx_lifecycle_mgr"

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


txLifecycleMgr = Dea::TxLifecycleManager.new(compProc)
node1 = Dea::NodeManager.instance
puts node1.addComponentObject(id,compProc)
compLifecycleMgr = Dea::CompLifecycleManager.new(compProc)
puts "---2---"
puts node1.setCompLifecycleManager(id,compLifecycleMgr)

node1.setTxLifecycleManager(id,txLifecycleMgr)
txMonitor = Dea::TxDepMonitor.new(compProc)
node1.getOndemandSetupHelper(id)

node1.setTxDepMonitor(id,txMonitor)
# TODO this to be tested thoroughly
#if this component is root and has no parent / root information in interceptor cache
txId = "9b096cee-475b-4359-acc9-46cdb934db1b"
txLifecycleMgr.createID(txId) 
puts txLifecycleMgr.txRegistry
puts txLifecycleMgr.compObject
# if we test a auth component , and it has a parent Proc in interceptor cache

#how can we ????
fakeTxId = txLifecycleMgr.createFakeTxId
puts fakeTxId

txContext = txLifecycleMgr.txRegistry.getTransactionContext(txId)
txLifecycleMgr.initLocalSubTx("compAuth", fakeTxId, txContext) 
 puts txLifecycleMgr.txRegistry
 
 
 
 ################### output ####################
# <["9b096cee-475b-4359-acc9-46cdb934db1b", root: ProcComponent 9b096cee-475b-4359-acc9-46cdb934db1b, parent: ProcComponent 9b096cee-475b-4359-acc9-46cdb934db1b, current: ProcComponent 9b096cee-475b-4359-acc9-46cdb934db1b futureC: pastC: subTxs:],
 # ["f7c35d60-a1bc-0131-5a11-080027880ca6", root: ProcComponent 9b096cee-475b-4359-acc9-46cdb934db1b, parent: ProcComponent 9b096cee-475b-4359-acc9-46cdb934db1b, current: compAuth f7c35d60-a1bc-0131-5a11-080027880ca6 TransactionStart, futureC: pastC: subTxs:],>

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

