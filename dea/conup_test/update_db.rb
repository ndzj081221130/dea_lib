# UTF-8
require_relative "../conup/remote_conf"


rcs = Dea::RemoteConf.new
ip = "192.168.12.34"
targetIdentifier = "DBComponent"
 
baseDir ="/vagrant/test/helloworld-db2"
 
protocol = "CONSISTENCY" 
rcs.updateApp(ip,targetIdentifier,protocol,baseDir,nil)

