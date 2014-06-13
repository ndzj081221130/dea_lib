# UTF-8
require_relative "../conup/client_sync"
require_relative "../conup/client"
require_relative "./constant"
require "json"
require_relative "../conup/client_sync_close"

ip="192.168.12.34"
port= Cons::PaPa_Port
msg = {}

msg["event_type"] = "FirstRequestService"
msg["name"] = "PaPaComponent"

fComps = Array.new
fComps << "HelloworldComponent"
fComps << "CallComponent"
msg["FutureComps"] = fComps
msg["PastComps"] = Array.new
msg["indeps"] = Array.new

deps = Array.new
deps << "HelloworldComponent"
deps << "CallComponent"
msg["deps"] = deps

msg["transaction_id"] = Cons::PaPa_Tx_id
msg["instance_id"] = Cons::PaPa_instance_id

msg["other_dea_port"] = "8000"
msg["other_dea_ip"] = "192.168.12.34"
msg["target_comp"] = "HelloworldComponent"

handle = msg.to_json
puts msg.to_json        

   Dea::ClientSyncClose.new(ip,port,msg.to_json) # call发起一个对hello的调用。此时，hello-dea可以维护这个事务信息


 