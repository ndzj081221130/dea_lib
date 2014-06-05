# coding: UTF-8
#conup-spi
require "steno"
require "steno/core_ext"


module Dea
  class TxDep
    
    attr_accessor :pastComponents # is an string array or rather , set
    attr_accessor :futureComponents  # is an string array
    
    def initialize(future,past) # future构件集合和past构件集合？
      @pastComponents = past 
      @futureComponents= future 
            
    end
    def <=>(other)
     # str1 = @type + @rootTx + @srcCompObjIdentifier + @targetCompObjIdentifier
     puts "called txdep <=>"
     str ="past:"
      pastComponents.each{|past|
          str += past +","
        
        }
        
     str += "\nfuture:"
     futureComponents.each{|future|
       str += future+","
       } 
       
      str2 = other.to_s
      return str  <=> str2
    end
    
    def to_s
      
      str ="tx_dep's past:"
      @pastComponents.each{|past|
          str += past +","
        
        }
        
     str += "\nfuture:"
     @futureComponents.each{|future|
       str += future+","
       }  
       str 
    end
    
    
  end
  
end

    