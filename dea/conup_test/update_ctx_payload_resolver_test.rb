# UTF-8

require_relative "../conup/update_context_payload_resolver"

payload = "OPERATION_TYPE:UPDATE,COMP_IDENTIFIER:HelloComponent,BASE_DIR:,CLASS_FILE_PATH:,CONTRIBUTION_URI:,COMPOSITE:"

resolver = Dea::UpdateContextPayloadResolver.new(payload)

opType = resolver.operation
puts "updateMgr: optype = #{opType}"  