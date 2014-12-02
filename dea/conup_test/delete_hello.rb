# DeleteComponent

    
require_relative "../conup/client_sync_response"

require_relative "../conup/comm_type"
require_relative "../conup/query_type"

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
      