# UTF-8

require_relative "../conup/dep_payload_resolver"
payload = "OPERATION_TYPE:REQ_ONDEMAND_SETUP,SRC_COMPONENT:HelloComponent,TARGET_COMPONENT:CallComponent,SCOPE:HelloComponent<CallComponent#CallComponent>HelloComponent#TARGET_COMP@HelloComponent#SCOPE_FLAG&false"

payloadResolver = Dea::DepPayloadResolver.new(payload)
      
      # puts "ondemand_setup: method ondemandSetup :  payload = #{payload}"
      operation = payloadResolver.operation
      
      puts operation
      curComp = payloadResolver.getParameter(Dea::DepPayload::TARGET_COMPONENT)
      puts curComp
      
scopeString = payloadResolver.getParameter(Dea::DepPayload::SCOPE)
puts scopeString

puts payloadResolver.getParameter(Dea::DepPayload::ROOT_TX)

