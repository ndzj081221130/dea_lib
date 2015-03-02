# UTF-8

require_relative "../conup/comm/client_once"

ip="192.168.12.34"
            port="8002"
            
# handle ="{\"PastComps\":[],\"indeps\":[\"CallComponent\"],"+
            # "\"event_type\":\"TransactionStart\",\"name\":\"HelloworldComponent\","+
            # "\"deps\":[],\"FutureComps\":[],\"transaction_id\":\"d967bf78-f867-4487-8c2e-19b9801b3392\","+
            # "\"instance_id\":\"b61fe621ae527f40c2075f59682453e1\"}"
#             
#             
#             
#             
# Dea::ClientOnce.new(ip,port,handle)
#other_dea_port
ref = "{\"PastComps\":[],\"indeps\":[],"+
            "\"other_dea_port\":\"8001\"" +","+
            "\"other_dea_ip\":\"192.168.12.34\""+ ","+
            "\"target_comp\":\"HelloComponent\"" +"," +
            "\"event_type\":\"FirstRequestService\",\"name\":\"CallComponent\","+
            "\"deps\":[\"CallComponent\"],\"FutureComps\":[\"HelloComponent\"],\"transaction_id\":\"call2967bf78-f867-4487-8c2e-19b9801b3392\","+
            "\"instance_id\":\"call261fe621ae527f40c2075f59682453e1\"}"
#
Dea::ClientOnce.new(ip,port,ref) # call发起一个对hello的调用。此时，hello-dea可以维护这个事务信息

#当有多个call请求同时发起时呢? hello-dea能不能正确维护？

