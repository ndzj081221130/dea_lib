# UTF-8
require_relative "./update_operation_type"
require_relative "./update_context_payload"

module Dea
  class UpdateContextPayloadResolver
    attr_accessor :operation
    attr_accessor :parameters #HashMap<UpdateContextPayload, String>
    
    def initialize(payload)
      @parameters = {} 
      resolve(payload)
      puts "update_context_payload_resolver #{payload}"
    end
    
    def getParameter(paraType) # UpdateContextPayload
      return @parameters[paraType]
    end
    
    # resolve payload
    def resolve(payload)
      keyValues = payload.split(/,/)
      # puts keyValues.size
      keyValues.each{|kv|
        
        pair = kv.split(/:/)
        # puts pair[0]
        if pair[0] == Dea::UpdateContextPayload::OPERATION_TYPE
          @operation= pair[1]
          # puts "pair[1] = #{pair[1]}"
        else
          @parameters[pair[0]]=pair[1]
        end
        }
    end
    
    
  end
end