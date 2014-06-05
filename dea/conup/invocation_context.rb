# coding: UTF-8
# conup-spi/datamodel
require "steno"
require "steno/core_ext"

module Dea
  class InvocationContext
    
    attr_accessor :rootTx #String
    attr_accessor :rootComp #String
    attr_accessor :parentTx #String
    attr_accessor :parentComp #String
    
    attr_accessor :subTx #String
    attr_accessor :subComp #String
    
    attr_accessor :invokeSequence #String
    
    def initialize(roottx, rootC, parenttx,parentC,subtx,subC,invokeS)
      @rootTx = roottx
      @rootComp = rootC
      @parentTx = parenttx
      @parentComp = parentC
      @subTx = subtx
      @subComp = subC
      @invokeSequence = invokeS
      
    end
    
    
    def to_s
      str = "INVOCATION_CONTEXT[" + @rootTx+":"+ @rootComp  + "," + @parentTx+":" + @parentComp  
      if @subTx && @subComp       
          str   += "," + @subTx+":" + @subComp;
        end
      if @invokeSequence       
            str +=
             "," + @invokeSequence+
             "]"
           end
      str
    end
    
     def InvocationContext.getTargetString(raw)#String
      if raw == nil
        return nil
      end
      
      if /\A\"/=~ raw
        l = raw.length
        raw = raw[1, l-1]
      end  
      
      if /\"\Z/=~ raw
        l2 = raw.length
        raw = raw[0,l2-1]
      end
      
      length = raw.length
      index = raw.index("INVOCATION_CONTEXT")
      sub = raw[index,length-index+1]
      head = sub.index("[") + 1
      tail = sub.index("]")
      
      return raw[head,tail - head + 1]
    end
    
    def InvocationContext.getInvocationCtx(ctxString)
      if ctxString == nil
        puts "invocationCtx: getInvocationCtx: ctx String nil"
        return
        
      end
      # puts "getInvo"
      puts ctxString
      if !ctxString.include? "INVOCATION_CONTEXT"
        #
        puts "invocationContext: not contains INvocation——Context"
      else
        target = InvocationContext.getTargetString(ctxString)
        txInfos = target.split(/,/)
        
        rootInfo = txInfos[0]
        parentInfo = txInfos[1]
        subInfo = txInfos[2]
        invoke = txInfos[3]
        
        rootInfos = rootInfo.split(/:/)
        rootTx = (rootInfos[0] != nil) ? rootInfos[0] : nil
        rootComponent = (rootInfos[1] != nil ) ? rootInfos[1] : nil
        
        parentInfos = parentInfo.split(/:/)
        parentTx = (parentInfos[0] != nil)?  parentInfos[0] :nil
        parentComponent = (parentInfos[1] != nil)?  parentInfos[1] : nil
        
        subInfos = subInfo.split(/:/)
        subTx = (subInfos[0] != nil)? subInfos[0] : nil
        subComponent = (subInfos[1] != nil)? subInfos[1] : nil
        
        return InvocationContext.new(rootTx,rootComponent,parentTx,parentComponent,
                                     subTx,subComponent, invoke)
        
      end
    end
    
   
    
  end
end
