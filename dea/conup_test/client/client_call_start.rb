# UTF-8
require_relative "../conup/client_sync"
require_relative "../conup/client"
require_relative "./constant"
require_relative "../conup/client_sync_close"

require "json"
ip="192.168.12.34"
port= Cons::Call_Port
msg = {}
msg["freeness"] = "blocking_strategy"
msg["event_type"] = "TransactionStart"
msg["name"] = "CallComponent"

msg["transaction_id"] = Cons::Call_Tx_Id
msg["instance_id"] = Cons::Call_Instance_Id


indeps = Array.new
indeps << "PaPaComponent"
msg["indeps"] = indeps

deps = Array.new
deps << "HelloworldComponent"
msg["deps"] = deps


fComps = Array.new
fComps << "HelloworldComponent"
msg["FutureComps"] = fComps


msg["PastComps"] = Array.new



handle = msg.to_json                       
Dea::ClientSyncClose.new(ip,port,handle) # txStart
 
  