# UTF-8
require_relative "./constant"
require_relative "../conup/client"
require_relative "../conup/client_sync"
require "json"
require_relative "../conup/client_sync_close"

ip="192.168.12.34"
port="8002"
msg = {}
msg["PastComps"] = Array.new
msg["indeps"] = Array.new
msg["event_type"] = "TransactionEnd"
msg["name"] = "PaPaComponent"
deps = Array.new
deps << "CallComponent"
deps << "HelloworldComponent"
msg["deps"] = deps
 
msg["transaction_id"] = Cons::PaPa_Tx_id2
msg["instance_id"] = Cons::PaPa_instance_id2   
 
 pComps = Array.new
 pComps << "CallComponent"
 pComps << "HelloworldComponent"
 msg["PastComps"] = pComps
 msg["FutureComps"] = []
 
  
  
 
 en = msg.to_json

Dea::ClientSyncClose.new(ip,port,en)

 
