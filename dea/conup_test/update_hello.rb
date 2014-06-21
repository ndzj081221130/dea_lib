# UTF-8
require_relative "../conup/remote_conf"


rcs = Dea::RemoteConf.new
ip = "192.168.12.34"
targetIdentifier = "HelloworldComponent"
 
baseDir ="/vagrant/test/helloworld-jsonrpc2"
classFilePath=""
contributionUri=""
compositeUri=""

 protocol = "CONSISTENCY" 

  rcs.updateApp(ip,targetIdentifier,protocol,baseDir,nil)

