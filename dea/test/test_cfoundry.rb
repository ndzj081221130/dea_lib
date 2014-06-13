#UTF-8

require_relative "./rest_client"
require_relative "./auth_token"

base_uri = "http://api.192.168.12.34.xip.io:8181/v2"
auth_header = "bearer eyJhbGciOiJIUzI1NiJ9.eyJqdGkiOiIxNmU3YmQ4NS04OGY1LTQ1MjAtOGMzZC05MTJhOTk1OGUzOGUiLCJzdWIiOiI2ZjgzMDU5Mi1kZTRmLTQ2YjEtYjc4My0xOGI4MzA2Y2UzZDEiLCJzY29wZSI6WyJjbG91ZF9jb250cm9sbGVyLmFkbWluIiwiY2xvdWRfY29udHJvbGxlci5yZWFkIiwiY2xvdWRfY29udHJvbGxlci53cml0ZSIsIm9wZW5pZCIsInBhc3N3b3JkLndyaXRlIiwic2NpbS5yZWFkIiwic2NpbS51c2VyaWRzIiwic2NpbS53cml0ZSJdLCJjbGllbnRfaWQiOiJjZiIsImNpZCI6ImNmIiwiZ3JhbnRfdHlwZSI6InBhc3N3b3JkIiwidXNlcl9pZCI6IjZmODMwNTkyLWRlNGYtNDZiMS1iNzgzLTE4YjgzMDZjZTNkMSIsInVzZXJfbmFtZSI6ImFkbWluIiwiZW1haWwiOiJhZG1pbiIsImlhdCI6MTQwMjQ1MzI0OCwiZXhwIjoxNDAyNDk2NDQ4LCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODAvdWFhL29hdXRoL3Rva2VuIiwiYXVkIjpbInNjaW0iLCJvcGVuaWQiLCJjbG91ZF9jb250cm9sbGVyIiwicGFzc3dvcmQiXX0.OKXWLcYf3ZhzSSjp-Gkn7rvfbHa-U8-jzsEIEdHbCU4"

refresh_token = "eyJhbGciOiJIUzI1NiJ9.eyJqdGkiOiJhYWM4YmVkNC04YzRiLTRhMzctYjE5Ni0zYTc4Mzg3MGUzYmUiLCJzdWIiOiI2ZjgzMDU5Mi1kZTRmLTQ2YjEtYjc4My0xOGI4MzA2Y2UzZDEiLCJzY29wZSI6WyJjbG91ZF9jb250cm9sbGVyLmFkbWluIiwiY2xvdWRfY29udHJvbGxlci5yZWFkIiwiY2xvdWRfY29udHJvbGxlci53cml0ZSIsIm9wZW5pZCIsInBhc3N3b3JkLndyaXRlIiwic2NpbS5yZWFkIiwic2NpbS51c2VyaWRzIiwic2NpbS53cml0ZSJdLCJpYXQiOjE0MDI0NTMyNDgsImV4cCI6MTQwNTA0NTI0OCwiY2lkIjoiY2YiLCJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwODAvdWFhL29hdXRoL3Rva2VuIiwiZ3JhbnRfdHlwZSI6InBhc3N3b3JkIiwidXNlcl9uYW1lIjoiYWRtaW4iLCJhdWQiOlsiY2xvdWRfY29udHJvbGxlci5hZG1pbiIsImNsb3VkX2NvbnRyb2xsZXIucmVhZCIsImNsb3VkX2NvbnRyb2xsZXIud3JpdGUiLCJvcGVuaWQiLCJwYXNzd29yZC53cml0ZSIsInNjaW0ucmVhZCIsInNjaW0udXNlcmlkcyIsInNjaW0ud3JpdGUiXX0.iR2s8nyWm6mxyfndyYeEbzh6V6DVKzO7GV9c-pSQHAQ"

token = CFoundry::AuthToken.new(auth_header,refresh_token)

target = "http://api.192.168.12.34.xip.io:8181"
rest_client = CFoundry::RestClient.new(target, token)



#path= "http://api.192.168.12.34.xip.io:8181/v2/spaces/d97b7b0e-1240-4b9e-a804-84a06f38f98d/summary"
 #path = "http://api.192.168.12.34.xip.io:8181/v2/apps/9e563be1-615f-4a23-9c37-25da85bfc351/instances"
                                                    #后面这个是app_id
 path = "http://api.192.168.12.34.xip.io:8181/v2/apps/4961c278-67cf-4909-bbd2-7b66fdef05b5/instances"
 method= "GET"
 options = {:accept=>:json}
# ===========================test2 cf stop if 
  path = "http://api.192.168.12.34.xip.io:8181/v2/apps/9e563be1-615f-4a23-9c37-25da85bfc351"
  path = base_uri +"/apps/4961c278-67cf-4909-bbd2-7b66fdef05b5"
  method = "PUT"
  options = {:content=>:json, :payload=>{:state=>"STOPPED"}, :return_response=>true}

# = ============================  test3 start app
path = base_uri + "/apps/4961c278-67cf-4909-bbd2-7b66fdef05b5"
method = "PUT"
options = {:content=>:json, :payload=>{:console=>true, :state=>"STARTED"}, :return_response=>true}


#=====================cf delete papa操作
path = base_uri + "/apps/4961c278-67cf-4909-bbd2-7b66fdef05b5?recursive=true"
method = "DELETE"

options = {:params=>{:recursive=>true}}













# =========================== real action  
  request, response = rest_client.request(method, path, options)

puts request

puts
puts response 
# ================

#如果是stop命令，需要参数：options: {:content=>:json, :payload=>{:state=>"STOPPED"}, :return_response=>true}
