# UTF-8

require_relative "../conup/client"
require "json"
require_relative "../conup/client_sync_close"
require_relative "./constant"
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
msg["transaction_id"] = Cons::PaPa_Tx_id2
msg["instance_id"] = Cons::PaPa_instance_id
handle = msg.to_json                       
Dea::ClientSyncClose.new(ip,port,handle) # txStart
 
 

#当有多个call请求同时发起时呢? hello-dea能不能正确维护？

