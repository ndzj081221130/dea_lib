# UTF-8
require_relative "../conup/remote_conf"


rcs = Dea::RemoteConf.new
ip = "192.168.12.34"
targetIdentifier = "CallComponent"
port = "8002"
baseDir ="/vagrant/test/call-helloworld2"
classFilePath=""
contributionUri=""
compositeUri=""
# 
# rcs.update
protocol = "CONSISTENCY"
# rcs.ondemand(ip,port,targetIdentifier,protocol,nil)
  rcs.update(ip,port,targetIdentifier,protocol,baseDir ,compositeUri,nil)

