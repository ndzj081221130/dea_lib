require_relative "../conup/client_once"

ref ="{\"PastComps\":[],\"indeps\":[\"ParentComponent\"],"+
            "\"event_type\":\"TransactionEnd\",\"name\":\"ChildComponent\","+
            "\"deps\":[],\"FutureComps\":[],\"transaction_id\":\"1967bf78-f867-4487-8c2e-19b9801b3392\","+
            "\"instance_id\":\"4096718b5d160e06313c707e683dd490\"}"
            
            
ip="192.168.12.34"
port="8002"
            

Dea::ClientOnce.new(ip,port,ref)


#{"PastComps":[],"indeps":["ParentComponent"],"event_type":"TransactionStart","name":"ChildComponent",
#"deps":[],"FutureComps":[],"transaction_id":"e19faa01-cab1-425c-9f57-db1d250b23ad",
#"instance_id":"4096718b5d160e06313c707e683dd490"}


#{"PastComps":[],"indeps":["ParentComponent"],"event_type":"TransactionEnd","name":"ChildComponent",
#"deps":[],"FutureComps":[],"transaction_id":"e19faa01-cab1-425c-9f57-db1d250b23ad",
#"instance_id":"4096718b5d160e06313c707e683dd490"}
