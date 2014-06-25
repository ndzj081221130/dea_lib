
require "steno"
require "steno/config"
require "steno/core_ext"

module ADB
  class CFS
    def initialize
      setup_logging
      
      logger.info("test ???")
    end
    
    
    def setup_logging
      
      @log_counter = Steno::Sink::Counter.new
       
       
      logging = {}#config["logging"]

      options = {
        :sinks => [],
      }

      if logging["level"]
        options[:default_log_level] = logging["level"].to_sym
      end
      logging["file"] = "test.log"
      if logging["file"]
        options[:sinks] << Steno::Sink::IO.for_file(logging["file"])
      end

      if logging["syslog"]
        Steno::Sink::Syslog.instance.open(logging["syslog"])
        options[:sinks] << Steno::Sink::Syslog.instance
      end

      if options[:sinks].empty?
        options[:sinks] << Steno::Sink::IO.new(STDOUT)
      end

      options[:sinks] << @log_counter

      Steno.init(Steno::Config.new(options))
      logger.info("Dea started")
    end
    
    
    private

    def logger
      @logger ||= self.class.logger
    end
    
    
  end
end


aa = ADB::CFS.new
