# UTF-8

require_relative "../conup/comp_updator"

updator = Dea::CompUpdator.new
#(baseDir,classPath,contributionURI,compositeURI,compIdentifier)

baseDir = "/vagrant/test/helloworld-jsonrpc"
classPath =""
contributionURI=""
compositeURI=""
compIdentifier = "HelloworldComponent"

id = compIdentifier
version="1.0"
alg="consistency"
freeConf="concurrent_version_for_freeness"
deps = Array.new #children#
deps << "DBComponent"

indeps = Array.new #parents
indeps << "PortalComponent"
implType="Java_POJO"
compProc = Dea::ComponentObject.new(id,version,alg,freeConf,deps,indeps,implType)
node1 = Dea::NodeManager.instance
puts node1.addComponentObject(id,compProc)
compLifecycleMgr = Dea::CompLifecycleManager.new(compProc,instance)
puts "---2---"
puts node1.setCompLifecycleManager(id,compLifecycleMgr)
txLifecycleMgr = Dea::TxLifecycleManager.new(compProc)
node1.setTxLifecycleManager(id,txLifecycleMgr)
txMonitor = Dea::TxDepMonitor.new(compProc)

txMonitor.txLifecycleMgr=txLifecycleMgr

puts node1.setTxDepMonitor(id,txMonitor)
# helper = OndemandSetupHelper.new(compProc)
node1.getOndemandSetupHelper(id)


updator.initUpdator(baseDir,classPath,contributionURI,compositeURI,compIdentifier)
updator.executeUpdate(compIdentifier)
