#UTF-8

require_relative "../../conup/client_sync"
require_relative "../../conup/node_mgr"
require 'json'
require 'set'
test = Set.new
test << "1234"
test << "1339d740-03b8-4d27-9b3d-08058d2541c3"
puts test.to_a 
# {"RootTx"=>"1234"}
# {"RootTx":"1234"}


handle = test.to_a.to_json
 
@json = JSON::parse(handle)

# puts @json
# puts @json.class

@json.each{|ai|
  puts "ai = #{ai}"
  }
