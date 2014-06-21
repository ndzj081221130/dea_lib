require_relative "../conup/client"
require_relative "../conup/client_go_response"
require_relative "./constant"
require "json" 
require 'eventmachine'



ip="192.168.12.34"
port="6666"
            
            
msg = {}

msg["InstanceId"] = "2203a1b2a76d5812d84ba6a67ecb2d7922ae051c75518d5804ae3a2a00f0be67"#Cons::Hello_Instance_Id
ref = msg.to_json      


client = Dea::ClientGoResponse.new(ip,port,ref)
 
puts client.response
puts client.response == nil