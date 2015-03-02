require_relative "../conup/comm/client_once"
require_relative "../conup/comm/client_sync_response"
require_relative "./constant"
require "json"
require_relative "../conup/comm/client_sync_close"
require 'eventmachine'
ip="192.168.12.34"
port="8000"
            
            
msg = {}
msg["freeness"] = "blocking_strategy"
msg["PastComps"] = Array.new

indeps = Array.new
indeps << "CallComponent"
indeps << "PaPaComponent"
msg["indeps"] = indeps
msg["event_type"] = "TransactionStart"
msg["name"] = "HelloworldComponent"
deps = Array.new
msg["deps"] = deps
fComps = Array.new

msg["FutureComps"] = fComps
msg["transaction_id"] = Cons::Hello_Tx_Id
msg["instance_id"] = Cons::Hello_Instance_Id
ref = msg.to_json      


client = Dea::ClientSyncResponse.new(ip,port,ref)
res = client.q
res.push "a"
puts "res = #{res} , res.size = #{res.size} \n\n"

 puts client.response