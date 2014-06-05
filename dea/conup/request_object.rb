# UTF-8
module Dea
  class RequestObject
    attr_accessor :srcIdentifier
    attr_accessor :targetIdentifier
    attr_accessor :protocol
    attr_accessor :msgType
    attr_accessor :payload
    attr_accessor :commType
    
     def initialize
       @srcIdentifier = ""
       @targetIdentifier = ""
       @protocol = ""
       @msgType=""
       @commType = ""
     end
     
    def to_s
      return "RequestObject: srcIdentifier: #{@srcIdentifier} targetIdentifier: #{@targetIdentifier} " + 
               "protocol: #{@protocol} payload: #{payload}"
    end
  end
end