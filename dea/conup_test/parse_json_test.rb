# UTF-8
require 'json'
require "set"

# '{"srcIdentifier"=>nil, "targetIdentifier"=>"HelloComponent", "protocol"=>"CONSISTENCY", "msgType"=>"ONDEMAND_MSG", "payload"=>"OPERATION_TYPE:ONDEMAND,COMP_IDENTIFIER:HelloComponent", "commType"=>"SYN"}'

 msg = {}
      msg["srcIdentifier"] = "srcIdentifier"
      msg["targetIdentifier"] = "targetIdentifier"
      msg["protocol"] = "protocol"
      msg["msgType"] = "msgType"
      msg["payload"] = "payload"
      msg["commType"] = "commType"
     

set = Set.new

puts set.to_a

set << "a"

puts set.to_a

msg["roots"] = set.to_a

 handle = msg.to_json
@json = JSON::parse(handle)
puts @json