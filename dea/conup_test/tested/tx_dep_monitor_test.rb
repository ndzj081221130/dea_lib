# UTF-8
require "../conup/tx_dep_monitor"
require "../conup/node_mgr"
#客户端发过来的内容:lddm: TransactionStart,d86393db-037a-44eb-9dbb-5e3e58ca0b24

#客户端发过来的内容:lddm: FirstRequestService,d86393db-037a-44eb-9dbb-5e3e58ca0b24

#请输入:  请输入:  客户端发过来的内容:lddm: DependencesChanged,d86393db-037a-44eb-9dbb-5e3e58ca0b24

#请输入:  客户端发过来的内容:lddm: TransactionEnd,d86393db-037a-44eb-9dbb-5e3e58ca0b24

# addFutureComponents and PastComponents

#请输入:  请输入:  客户端发过来的内容:lddm: TransactionStart,0a2e5a9d-b8d3-42d7-b436-49237597c966;
#Future:cn.edu.nju.moon.conup.sample.proc.services.DBService,;Past:

#客户端发过来的内容:lddm: FirstRequestService,0a2e5a9d-b8d3-42d7-b436-49237597c966;
#Future:cn.edu.nju.moon.conup.sample.proc.services.DBService,;Past:

#请输入:  请输入:  客户端发过来的内容:lddm: DependencesChanged,0a2e5a9d-b8d3-42d7-b436-49237597c966

#请输入:  客户端发过来的内容:lddm: TransactionEnd,0a2e5a9d-b8d3-42d7-b436-49237597c966;
#Future:;Past:cn.edu.nju.moon.conup.sample.proc.services.DBService,


#客户端发过来的内容:lddm: TransactionStart,9b096cee-475b-4359-acc9-46cdb934db1b;
                       #Future:cn.edu.nju.moon.conup.sample.proc.services.DBService,;Past:

#请输入:  客户端发过来的内容:lddm: FirstRequestService,9b096cee-475b-4359-acc9-46cdb934db1b;
                               #Future:cn.edu.nju.moon.conup.sample.proc.services.DBService,;Past:


#请输入:  客户端发过来的内容:lddm: DependencesChanged,9b096cee-475b-4359-acc9-46cdb934db1b;Future:;
                        #Past:cn.edu.nju.moon.conup.sample.proc.services.DBService,

#请输入:  客户端发过来的内容:lddm: TransactionEnd,9b096cee-475b-4359-acc9-46cdb934db1b;
                        #Future:;Past:cn.edu.nju.moon.conup.sample.proc.services.DBService,



id = "ProcComponent"
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
compLifecycleMgr = Dea::CompLifecycleManager.new(compProc)
puts "---2---"
puts node1.setCompLifecycleManager(id,compLifecycleMgr)
txLifecycleMgr = Dea::TxLifecycleManager.new(compProc)
node1.setTxLifecycleManager(id,txLifecycleMgr)
txMonitor = Dea::TxDepMonitor.new(compProc)

txMonitor.txLifecycleMgr=txLifecycleMgr

puts node1.setTxDepMonitor(id,txMonitor)
# helper = OndemandSetupHelper.new(compProc)
node1.getOndemandSetupHelper(id)
txLifecycleMgr.createID("9b096cee-475b-4359-acc9-46cdb934db1b") 
# what ID , java create uuid in txLifecycleMgr
#06b39002-e165-85dd-0b80612ad7b4
# txMonitor.notify("TransactionStart","9b096cee-475b-4359-acc9-46cdb934db1b",["DBcomponent"],[])
# puts 1
# puts txMonitor.txDepRegistry
# 
# txMonitor.notify("FirstRequestService","9b096cee-475b-4359-acc9-46cdb934db1b",["DBcomponent"],[])
# puts 2
# puts txMonitor.txDepRegistry
# 
txMonitor.notify("DependencesChanged","9b096cee-475b-4359-acc9-46cdb934db1b",[],["DBcomponent"])
puts 3
puts txMonitor.txDepRegistry
# 
txMonitor.notify("TransactionEnd","9b096cee-475b-4359-acc9-46cdb934db1b",[],["DBcomponent"])
# puts 4
# puts "#{txMonitor.txDepRegistry} size = #{txMonitor.txDepRegistry.size}" 

#TODO to add test  case!!!
#puts txMonitor.isLastUse()


##############output################









































