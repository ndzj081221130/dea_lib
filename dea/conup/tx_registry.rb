# coding: UTF-8
#conup-spi
require "steno"
require "steno/core_ext"
require_relative "./tx_context"

module Dea
  class TransactionRegistry
    
    
    attr_accessor :txContexts #Hash<tid, TxContext>
    
    def initialize
      @txContexts = Hash.new #Hash<tid, TxContext>
    end
    
    def getTransactionContext(transactionID)
      return @txContexts[transactionID]
    end
    
    def getTransactionContexts
      return @txContexts 
    end
    
    def addTransactionContext(transtionID, transactionContext)
      if @txContexts == nil
        puts "nil txCtx"
      end
      @txContexts[transtionID]=transactionContext
    end
   
    def removeTransactionContext(transactionID)
      @txContexts.delete(transactionID)
    end
    
    def contains(transactionID)
      return @txContexts[transactionID]
    end
    
    def updateTransactionContext(transactionID,transactionContext)
      @txContexts.delete(transactionID)
      @txContexts[transactionID] = transactionContext
    end
    
    def getAllTxIds
      return @txContexts.keys
    end

    def to_s
       	str = "<"
      	@txContexts.each{|txCtx|
      	    	str += txCtx.to_s + ",\n"
          }
        str+= ">"
        str
    end
  end
end
