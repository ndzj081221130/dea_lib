# coding: UTF-8

require "steno"
require "steno/core_ext"

module Dea
  class DepPayload
    
    SRC_COMPONENT="SRC_COMPONENT"
    SRC_PORT = "SRC_PORT"
    
    TARGET_COMPONENT="TARGET_COMPONENT"
    
    ROOT_TX="ROOT_TX"
    OPERATION_TYPE="OPERATION_TYPE"
    
    PARENT_TX="PARENT_TX"
    SUB_TX="SUB_TX"
    SCOPE="SCOPE"
    
    attr_accessor :payload
    def initialize(pay)
      @payload = pay
    end
    
    def to_s
      return @payload.to_s
    end
  end
end
