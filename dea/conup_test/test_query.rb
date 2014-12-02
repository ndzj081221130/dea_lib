      
require_relative "../conup/client_sync_response"

require_relative "../conup/comm_type"
require_relative "../conup/query_type"

require 'json'

targetIdentifier = "HelloworldComponent"  
 protocol = "login.192.168.12.34"
baseDir ="/vagrant/test/helloworld-jsonrpc2"

      ip = "192.168.12.34"
      port = 8700
      msg = {}
      
      
      ##############test1 ###############
      # msg["msgType"] = Dea::QueryType::Components      
      # msg["componentName"] = targetIdentifier
#       
      # client = Dea::ClientSyncResponse.new(ip,port,msg.to_json)      
      # response = client.response
      # puts "#{response }"
        
        
        
 
# ===========================test2 #####################3
        # msg["msgType"] = Dea::QueryType::Instances
        # client2 = Dea::ClientSyncResponse.new(ip,port,msg.to_json)
#         
      # response = client2.response
      # puts "\n#{response } \n"
      

# =====================test3 ###########################

# 
# msg["msgType"] = Dea::QueryType::Instance
# msg["componentName"] = "db"
# client3 = Dea::ClientSyncResponse.new(ip,port,msg.to_json)
#         
# response = client3.response
# puts "#{response }"


##############################test4 #########################

# msg["msgType"] = Dea::QueryType::AddComponent
# msg["componentName"] = "HelloworldComponent"
# msg["componentVersionPort"] = "8001"
# clienta = Dea::ClientSyncResponse.new(ip,port,msg.to_json)
# response = clienta.response
# puts "#{response}"

######### test5 #####################
# msg["msgType"] = Dea::QueryType::ComponentLifecycleMgr
# msg["componentName"] = "HelloworldComponent"
# msg["componentVersionPort"] = "8000"
# 
# client4 = Dea::ClientSyncResponse.new(ip,"8701",msg.to_json)
# 
# puts client4.response

###################test6################## 
# msg["msgType"] = Dea::QueryType::TxLifecycleMgr
# msg["componentName"] = "HelloworldComponent"
# msg["componentVersionPort"] = "8000"
# 
# client5 = Dea::ClientSyncResponse.new(ip,"8701",msg.to_json)
# 
# puts client5.response

#######################test7 #############3
msg["msgType"] = Dea::QueryType::DrawRegistryTable
client6 = Dea::ClientSyncResponse.new(ip,port,msg.to_json)

puts client6.response 








