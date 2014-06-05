require_relative "../conup/consistency_payload_creator"

res = Dea::ConsistencyPayloadCreator.createRemoteUpDateIsDonePayload("HelloComponent","CallComponent","remoteuuu")
#""   ConsistencyPayloadCreator.createRemoteUpDateIsDonePayload
puts res

puts "---4 "

puts Dea::ConsistencyPayloadCreator.createPayload4("a","b","c","d")

puts "===5"
puts Dea::ConsistencyPayloadCreator.createPayload5("e","a","b","c","d")

puts "----6"
puts Dea::ConsistencyPayloadCreator.createPayload6("d,","sd","a","b","c","d")

puts Dea::ConsistencyPayloadCreator.createNormalRootTxEndPayload("aa","bv","cd","ds")

puts ""
