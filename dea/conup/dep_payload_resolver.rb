# coding: UTF-8

require "steno"
require "steno/core_ext"
# require_relative "./dep_op_type"
require_relative "./dep_payload"

module Dea
  class DepPayloadResolver
    attr_accessor :operation
    attr_accessor :params
    
    def initialize(payload) # string
      @params= {}
      resolve(payload)
    end
    
    def getParameter(type) #DepPayload
      return @params[type]
    end
    
    
    
    def resolve(payload) #String
      
      keyValues = payload.split(/,/);
      #puts keyValues
#puts
      keyValues.each{|kv|
        pair = kv.split(/:/)
       # puts "pair = #{pair}"
        depPayload = pair[0]#DepPayload.new()
	#puts "payload = #{depPayload}"
#puts DepPayload::OPERATION_TYPE
#puts depPayload.to_s == Dea::DepPayload::OPERATION_TYPE

        if depPayload.to_s == DepPayload::OPERATION_TYPE
          @operation = pair[1]#DepPayload.new()
			#puts        "if"
 #puts @operation
        else
          @params[depPayload.to_s] = pair[1]
        end
       # puts @operation
        }
      
    end
  end
end
