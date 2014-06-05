require_relative "../conup/client"
require_relative "../conup/client_sync"
require_relative "./constant"
require "json"
 require_relative "../conup/client_sync_close"

ip="192.168.12.34"
port="8000"
            
            
msg = {}
msg["freeness"] = "blocking_strategy"
msg["PastComps"] = Array.new

indeps = Array.new
indeps << "CallComponent"
indeps << "PaPaComponent"
msg["indeps"] = indeps
msg["event_type"] = "TransactionStart"
msg["name"] = "HelloworldComponent"
deps = Array.new
msg["deps"] = deps
fComps = Array.new

msg["FutureComps"] = fComps
msg["transaction_id"] = Cons::Hello_Tx_Id
msg["instance_id"] = "161fe621ae527f40c2075f59682453e1"
ref = msg.to_json      


Dea::ClientSyncClose.new(ip,port,ref)

