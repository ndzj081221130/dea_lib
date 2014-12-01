# UTF-8
require_relative "../conup/client_sync_close"
require_relative "./constant"
require_relative "../conup/client"
require_relative "../conup/client_sync"
 
 

ip="192.168.12.34"
port="8001"
msg = {}
msg["freeness"] = "blocking_strategy"
msg["PastComps"] = Array.new
 
msg["event_type"] = "TransactionStart"
msg["name"] = "CallComponent"
deps = Array.new
deps << "HelloworldComponent"
msg["deps"] = deps

indeps = Array.new
indeps << "PaPaComponent"
msg["indeps"] = indeps


fComps = Array.new
fComps << "HelloworldComponent"
msg["FutureComps"] = fComps
msg["transaction_id"] = Cons::Call_Tx_Id2
msg["instance_id"] = Cons::Call_Instance_Id2
handle = msg.to_json                       
Dea::ClientSyncClose.new(ip,port,handle) # txStart

 
