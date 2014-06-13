# UTF-8
require_relative "../conup/remote_conf"


rcs = Dea::RemoteConf.new
ip = "192.168.12.34"
targetIdentifier = "DBComponent"
port = "8001"
baseDir ="/vagrant/test/helloworld-db2"
classFilePath=""
contributionUri=""
compositeUri=""

 protocol = "CONSISTENCY" 
 

  rcs.update(ip,port,targetIdentifier,protocol,baseDir,compositeUri,nil)

