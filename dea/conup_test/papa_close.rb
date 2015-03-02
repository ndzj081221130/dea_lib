# UTF-8
require_relative "./constant" 
require "json"
require_relative "../conup/comm/client_sync_close"

ip="192.168.12.34"
port= Cons::PaPa_Port
msg = {}
msg["operation"] = "STOP"

 
 cha = msg.to_json
  

 Dea::ClientSyncClose.new(ip,port,cha)

 