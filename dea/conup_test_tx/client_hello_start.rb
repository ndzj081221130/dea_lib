require_relative "../conup/comm/client_once"

ref ="{\"PastComps\":[],\"indeps\":[\"CallComponent\"],"+
            "\"event_type\":\"TransactionStart\",\"name\":\"HelloComponent\","+
            "\"deps\":[],\"FutureComps\":[],\"transaction_id\":\"1967bf78-f867-4487-8c2e-19b9801b3392\","+
            "\"instance_id\":\"161fe621ae527f40c2075f59682453e1\"}"
            
            
            ip="192.168.12.34"
            port="8001"
            

Dea::ClientOnce.new(ip,port,ref)

