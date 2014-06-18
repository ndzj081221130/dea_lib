require_relative "../conup/client"
require_relative "../conup/client_go_response"
require_relative "./constant"
require "json" 
require 'eventmachine'



ip="localhost"
port="6666"
            
            
msg = {}

msg["InstanceId"] = Cons::Hello_Instance_Id
ref = msg.to_json      


client = Dea::ClientGoResponse.new(ip,port,ref)
 

 puts client.response