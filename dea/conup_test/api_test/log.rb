#UTF-8

require 'logger'

class AFD
  
    def initialize
      logger.debug "adg"
    end
    def logger
      @logger ||= Logger.new("/vagrant/logs/ts.log")
    end

    def logger=(logger)
      @logger = logger
    end
end


AFD.new