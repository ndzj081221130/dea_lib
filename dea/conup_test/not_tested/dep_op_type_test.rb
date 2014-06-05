# UTF-8
require "../conup/dep_op_type"

if "ACK_SUBTX_INIT" == Dea::DepOperationType::ACK_SUBTX_INIT
  puts "equal ACK_SUBTX_INIT"
else
  puts "not equal ACK_SUBTX_INIT"
end