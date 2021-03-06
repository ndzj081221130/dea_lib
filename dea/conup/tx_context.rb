# coding: UTF-8

require "steno"
require "steno/core_ext"
require_relative "./scope"

module Dea
  class TxContext

    attr_accessor :currentTx
    attr_accessor :hostComponent
    attr_accessor :rootTx
    attr_accessor :rootComponent
    attr_accessor :parentTx
    attr_accessor :parentComponent

    attr_accessor :eventType #String
    attr_accessor :isFakeTx #boolean

    attr_accessor :subTxHostComps #Map<String , String > key=subTx,value=host Components
    attr_accessor :subTxStatuses #Map<String,TxEventType> # change To <String,String>

    attr_accessor :invocationSequence
    def initialize
      @subTxHostComps = {}
      @subTxStatuses = {}
      @isFakeTx=false
      @currentTx=""
      @hostComponent=""
      @rootTx=""
      @rootComponent=""
      @parentTx=""
      @parentComponent=""
    end

    def getProxyRootTxId(scope)
      
      if scope == nil || !scope.isSpecifiedScope
        # puts "tx_context: getProxyRootTxId , scope == nil or isSpecifiedScope in if false"
        return @rootTx
      else
        proxyRootTxId = calcProxyTxId(rootTx,hostComponent, scope)
        if proxyRootTxId == nil
          # puts "nil"
          return @rootTx
        else
          # puts "not nil"
        return proxyRootTxId
        end
      end
    end

    def calcProxyTxId(root,host,scope)
      proxyRootComps = scope.getRootComp(host) #proxyRootComp is an array
      if @invocationSequence == nil || @invocationSequence == "nil"
        return currentTx
      end

      sequences = @invocationSequence.split(/>/)
      seq1 = sequences[0]
      puts seq1
      if scope.contains(seq1.split(/:/)[0])  && proxyRootComps.include?(host)
        return rootTx
      end
      puts proxyRootComps.size
      proxyRootComps.each{|proxyRootComp|
        if @invocationSequence.index(proxyRootComp)
          #entities = @invocationSequence.split(/>/)
          sequences.each{|sequence|
            if sequence.index(proxyRootComp)
              # puts "contains"
              return sequence.split(/:/)[1]
            end
          }
        end
      }

      return currentTx

    end
    
    def to_s
      result = "root: " + @rootComponent + " " + @rootTx + ", " +
              "parent: " + @parentComponent + " " + @parentTx + ", " 
      if !@hostComponent
              result +=
              "current: " + @hostComponent +
              " " + @currentTx +" " 
      end
       
      if @eventType!=nil
         result += @eventType +", " 
      end      
       
       result += "subTxs:"
       
       if !@subTxHostComps
       @subTxHostComps.each{ |key , value|
          result += "\n" + key +" " + value + " " + @subTxStatuses[key]
       } 
       end      
      return result 
    end
    
    
    
  end

end
