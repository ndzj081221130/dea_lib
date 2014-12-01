# UTF-8
require_relative "../conup/remote_conf"
require_relative "../conup/update_context_payload_creator"

rcs = Dea::RemoteConf.new
ip = "192.168.12.34"
targetIdentifier = "HelloworldComponent"
port = "8000"
baseDir ="/vagrant/test/helloworld-jsonrpc2"
classFilePath=""
contributionUri=""
compositeUri=""
# 
# rcs.update
protocol = "CONSISTENCY"
# rcs.ondemand(ip,port,targetIdentifier,protocol,nil)
  # rcs.update(ip,port,targetIdentifier,protocol,baseDir,classFilePath,contributionUri,compositeUri,nil)


t1 = Dea::UpdateContextPayloadCreator.createPayload( targetIdentifier,protocol,baseDir,classFilePath,contributionUri,compositeUri,nil)

puts t1

t2 = Dea::UpdateContextPayloadCreator.createPayload(targetIdentifier,protocol,nil)

puts t2


# OPERATION_TYPE + ":" + args[0] + "," + 
                 # Dea::UpdateContextPayload::COMP_IDENTIFIER + ":" + args[1] + "," + 
                 # Dea::UpdateContextPayload::BASE_DIR + ":" + args[2] + "," + 
                 # Dea::UpdateContextPayload::CLASS_FILE_PATH + ":" + args[3] + "," + 
                 # Dea::UpdateContextPayload::CONTRIBUTION_URI + ":" + args[4] + "," +
                 # Dea::UpdateContextPayload::COMPOSITE_URI 