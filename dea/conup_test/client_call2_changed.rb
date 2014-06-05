# UTF-8
require_relative "./constant"
require_relative "../conup/client"
require_relative "../conup/client_sync"
require "json"
require_relative "../conup/client_sync_close"

ip="192.168.12.34"
port="8001"
msg = {}
msg["PastComps"] = Array.new
 
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

 msg["event_type"] = "DependencesChanged"
 pComps = Array.new
 pComps << "HelloworldComponent"
 msg["PastComps"] = pComps
 msg["FutureComps"] = []
 
 cha = msg.to_json
  

 Dea::ClientSyncClose.new(ip,port,cha)

 