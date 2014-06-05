# UTF-8

require_relative "../conup/client"
require_relative "../conup/client_sync"
require_relative "./constant"
require "json"
require_relative "../conup/client_sync_close"

ip="192.168.12.34"
port="8002"
msg = {}
msg["freeness"] = "blocking_strategy"
msg["PastComps"] = Array.new
msg["indeps"] = Array.new
msg["event_type"] = "TransactionStart"
msg["name"] = "PaPaComponent"
deps = Array.new
deps << "HelloworldComponent"
deps << "CallComponent"
msg["deps"] = deps
fComps = Array.new
fComps << "HelloworldComponent"
fComps << "CallComponent"
msg["FutureComps"] = fComps
msg["transaction_id"] = Cons::PaPa_Tx_id
msg["instance_id"] = Cons::PaPa_instance_id
handle = msg.to_json                       
Dea::ClientSyncClose.new(ip,port,handle) # txStart
 
 

 