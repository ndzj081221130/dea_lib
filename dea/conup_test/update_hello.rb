# UTF-8
require_relative "../conup/remote_conf"
require 'date'


rcs = Dea::RemoteConf.new
ip = "192.168.12.34"
targetIdentifier = "HelloworldComponent"
baseDir ="/vagrant/test/helloworld-jsonrpc2"
classFilePath=""
contributionUri=""
compositeUri="auth.192.168.12.34.xip.io"
protocol = "CONSISTENCY" 
today = Time.new
puts today
rcs.updateApp(ip,targetIdentifier,protocol,baseDir,compositeUri)

