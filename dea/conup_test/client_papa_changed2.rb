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
msg["name"] = "PaPaComponent"
deps = Array.new
deps << "CallComponent"
msg["deps"] = deps
fComps = Array.new
fComps << "CallComponent"
fComps << "HelloworldComponent"

msg["FutureComps"] = fComps
msg["transaction_id"] = Cons::PaPa_Tx_id
msg["instance_id"] = Cons::PaPa_instance_id

 msg["event_type"] = "DependencesChanged"
 pComps = Array.new
 pComps << "HelloworldComponent"
 pComps << "CallComponent"
 
 msg["PastComps"] = pComps
 msg["FutureComps"] = []
 
 cha = msg.to_json
  

 Dea::ClientSyncClose.new(ip,port,cha)

 