# coding: UTF-8
#conup-spi/datamodel
require "steno"
require "steno/core_ext"
require_relative "./tx_dep"

module Dea
  class TxDepRegistry
    
    attr_accessor :txDeps #Hash<txID,txDep>
    
    
    def initialize
      @txDeps = {}
    end
    
    
    def size
      return @txDeps.size
    end
    
    
    def getLocalDep(txId)
	 
      return @txDeps[txId] # return TxDep 
    end
    
    def addLocalDep(txId , txDep)
      if contains(txId) == false
        @txDeps[txId] = txDep            
      else
         puts "txDep store"
        @txDeps.store(txId,txDep) # @txDeps[txId] = txDep
      end
        
    end
    
    def removeLocalDep(txId)
      puts "txDepRegistry.removeLocal #{txId}"
      @txDeps.delete(txId)
    end
    
    def contains(txId)
      return @txDeps.has_key?(txId)
    end

	  def to_s
	    if @txDeps.size ==0
	       return "TxDepRegistry.size =0"
	    end
	    @txDeps.each{|id,dep|
	      
	      puts "id: #{id} ,  dep: #{dep} \n---\n"
	      }
	  end

  end
end

 