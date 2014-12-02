# UTF-8

require_relative "../conup/client"
require "json"
ip="192.168.12.34"
port="8002"
msg = {}
msg["PastComps"] = Array.new
msg["indeps"] = Array.new
msg["event_type"] = "TransactionStart"
msg["name"] = "CallComponent"
deps = Array.new
deps << "HelloComponent"
msg["deps"] = deps
fComps = Array.new
fComps << "HelloComponent"
msg["FutureComps"] = fComps
msg["transaction_id"] = "d967bf78-f867-4487-8c2e-19b9801b3392"
msg["instance_id"] = "b61fe621ae527f40c2075f59682453e1"

 handle = msg.to_json
                       
   # Dea::ClientOnce.new(ip,port,handle) # txStart
 

 ref = "{\"PastComps\":[],\"indeps\":[],"+
            "\"other_dea_port\":\"8001\"" +","+
            "\"other_dea_ip\":\"192.168.12.34\""+ ","+
            "\"target_comp\":\"HelloComponent\"" +"," +
            "\"event_type\":\"FirstRequestService\",\"name\":\"CallComponent\","+
            "\"deps\":[\"HelloComponent\"],\"FutureComps\":[\"HelloComponent\"],\"transaction_id\":\"d967bf78-f867-4487-8c2e-19b9801b3392\","+
            "\"instance_id\":\"b61fe621ae527f40c2075f59682453e1\"}"

   #Dea::ClientOnce.new(ip,port,ref) # call发起一个对hello的调用。此时，hello-dea可以维护这个事务信息



 msg["event_type"] = "DependencesChanged"
 pComps = Array.new
 pComps << "HelloComponent"
 msg["PastComps"] = pComps
 msg["FutureComps"] = []
 
 cha = msg.to_json
  
# 
 Dea::ClientOnce.new(ip,port,cha)


# 4
# msg["event_type"] = "TransactionEnd"
# en = msg.to_json
# 
# Dea::ClientOnce.new(ip,port,en)



#当有多个call请求同时发起时呢? hello-dea能不能正确维护？

