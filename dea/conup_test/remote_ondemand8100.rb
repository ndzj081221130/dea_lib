# UTF-8
require_relative "../conup/remote_conf"


rcs = Dea::RemoteConf.new
ip = "192.168.12.34"
targetIdentifier = "HelloworldComponent"
port = "8100"
baseDir ="/vagrant/test/helloworld-jsonrpc2"
classFilePath=""
contributionUri=""
compositeUri=""
# 
# rcs.update
protocol = "CONSISTENCY"
rcs.ondemand(ip,port,targetIdentifier,protocol,nil)
  # rcs.update(ip,port,targetIdentifier,protocol,baseDir,classFilePath,contributionUri,compositeUri,nil)

