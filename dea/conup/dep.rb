# coding: UTF-8

require "steno"
require "steno/core_ext"


module Dea
  class Dependence
    include Comparable
    
    attr_accessor :type
    attr_accessor :rootTx
    attr_accessor :srcCompObjIdentifier
    attr_accessor :targetCompObjIdentifier
    
    attr_accessor :sourceService
    attr_accessor :targetService
    
    def initialize(type1,rootTx1,srcCompObjIdentifier1,targetCompObjIdentifier1,sourceService1,targetService1)
      @type =  type1
      @rootTx =  rootTx1
      @srcCompObjIdentifier =  srcCompObjIdentifier1
      @targetCompObjIdentifier =  targetCompObjIdentifier1
      
      @sourceService =  sourceService1
      @targetService = targetService1
    end
    
    def Dependence.createByDep(dep)
      new(dep.type,dep.rootTx,dep.srcCompObjIdentifier,
                    dep.targetCompObjIdentifier,dep.sourceService,dep.targetService)
    end
    
    def <=>(other)
      puts "called txdep <=>"
      str1 = @type + @rootTx + @srcCompObjIdentifier + @targetCompObjIdentifier
      str2 = other.type + other.rootTx + other.srcCompObjIdentifier + other.targetCompObjIdentifier
      return str1 <=> str2
    end
    
     def eql?(other)
        return false unless other.instance_of?(self.class)
        @type == other.type && @rootTx == other.rootTx && @srcCompObjIdentifier == other.srcCompObjIdentifier && @targetCompObjIdentifier == other.targetCompObjIdentifier
        
     end
    
    def hash
    #a.hash ^ b.hash # 异或
      @type.hash ^ @rootTx.hash ^ @srcCompObjIdentifier.hash ^ @targetCompObjIdentifier.hash
    end
    
    def to_s
      
      str = @type +"," + @rootTx + ",src:" + @srcCompObjIdentifier +",target:" + @targetCompObjIdentifier
      if @sourceService
         str += ",ss:"+  @sourceService
       end
      if @targetService
         str += ", ts:" + @targetService 
      end
      str
    end
    
    
    
    
  end
  
  
end
