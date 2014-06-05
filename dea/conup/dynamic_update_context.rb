# UTF-8
# extension : POJODynamicUpdateContext
require "set"

module Dea
  class DynamicUpdateContext
    
    
    
    attr_accessor :oldVerClass
    attr_accessor :newVerClass
    
    attr_accessor :isLoaded
    attr_accessor :algorithmOldRootTxs #Set<string>
    
    def initialize
      puts "update_ctx: new"
      isLoaded=false
      @algorithmOldRootTxs = nil
      @oldVerClass = nil
      @newVerClass = nil
    end
     
    def removeAlgorithmOldRootTx(oldRootTx)
      puts "in DynamicUpdateContext.removeAlgorithmOldTx() ,rm #{oldRootTx}"      
      @algorithmOldRootTxs.delete oldRootTx
    end
    
    def isOldRootTxsInitiated
      puts "dynamic_update_tx: isOldRootTxsInitiated"
      puts @algorithmOldRootTxs != nil
      # puts "before return"
      return @algorithmOldRootTxs != nil #这句话是return了的
    end
  end
end