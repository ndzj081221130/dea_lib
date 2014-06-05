# UTF-8
require_relative "../conup/client_sync"
require_relative "../conup/client"
require "json"
require_relative "../conup/client_sync_close"
require_relative "./constant"
 

  
ip="192.168.12.34"
port="8001"
msg = {}
msg["PastComps"] = Array.new

msg["event_type"] = "FirstRequestService"
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
msg["other_dea_port"] ="8000"
msg["other_dea_ip"] = "192.168.12.34"
msg["target_comp"] = "HelloworldComponent"
handle = msg.to_json
                       
res = Dea::ClientSyncClose.new(ip,port,handle) # txStart
 
