      
require_relative "../conup/client_sync_response"

require_relative "../conup/comm_type"
require_relative "../conup/query_type"

require 'json'

targetIdentifier = "DBComponent"
# port = "8000"
baseDir ="/vagrant/test/helloworld-jsonrpc2"

      ip = "192.168.12.34"
      port = "8700"
      msg = {}
      msg["msgType"] = Dea::QueryType::Components      
      msg["componentName"] = targetIdentifier
      
      client = Dea::ClientSyncResponse.new(ip,port,msg.to_json)
      
      response = client.response
      puts "#{response }"
       jsonArray = JSON::parse(response)
       jsonArray.each{|ports|
         puts "port = #{ports}"
       #  update(ip,port,targetIdentifier,protocol,baseDir,"",scope)
         
        }