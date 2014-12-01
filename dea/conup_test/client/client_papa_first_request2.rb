# UTF-8
require_relative "../conup/client_sync"
require_relative "../conup/client"
require_relative "./constant"
require "json"
require_relative "../conup/client_sync_close"

ip="192.168.12.34"
port= Cons::PaPa_Port
msg = {}
msg["PastComps"] = Array.new
msg["indeps"] = Array.new
msg["event_type"] = "FirstRequestService"
msg["name"] = "PaPaComponent"
deps = Array.new
deps << "HelloworldComponent"
deps << "CallComponent"
msg["deps"] = deps
fComps = Array.new
fComps << "CallComponent"
msg["FutureComps"] = fComps
msg["transaction_id"] = Cons::PaPa_Tx_id
msg["instance_id"] = Cons::PaPa_instance_id

msg["other_dea_port"] = Cons::Call_Port
msg["other_dea_ip"] = "192.168.12.34"
msg["target_comp"] = "CallComponent"

handle = msg.to_json
puts msg.to_json        

Dea::ClientSyncClose.new(ip,port,msg.to_json) # call发起一个对hello的调用。此时，hello-dea可以维护这个事务信息


 