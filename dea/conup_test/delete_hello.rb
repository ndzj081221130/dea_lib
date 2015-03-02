# DeleteComponent

    
require_relative "../conup/comm/client_sync_response"

# require_relative "../conup/datamodel/comm_type"
require_relative "../conup/datamodel/query_type"

require 'json'

targetIdentifier = "HelloworldComponent"
protocol = "auth.192.168.12.34"
baseDir ="/vagrant/test/helloworld-jsonrpc2"

      ip = "192.168.12.34"
      port = "8700"
      msg = {}
      msg["msgType"] = Dea::QueryType::DeleteComponent      
      msg["componentName"] = targetIdentifier
      
      client = Dea::ClientSyncResponse.new(ip,port,msg.to_json)
      
      response = client.response
      puts "#{response }"
      