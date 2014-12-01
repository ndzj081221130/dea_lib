require_relative "../conup/client_sync"
 require_relative "./constant" 
            
 require_relative "../conup/client_sync_close"
 
ip="192.168.12.34"
port="8010"
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
msg["transaction_id"] = Cons::Hello_Tx_Id2
msg["instance_id"] = Cons::Hello_Instance_Id2 
ref = msg.to_json      

Dea::ClientSyncClose.new(ip,port,ref)

