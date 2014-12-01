#UTF-8

module DEA
  class FSD
    attr_reader :logger
    def initialize (custom_logger = nil)
      @logger = custom_logger || self.class.logger.tag({})
      
      
    end
  
    def atest   
      logger.info("something interesting")
    end
    def logger
      tags = {
        # "instance_id"         => instance_id,
        # "instance_index"      => instance_index,
        # "application_id"      => application_id,
        # "application_version" => application_version,
        # "application_name"    => application_name,
      }

      @logger ||= self.class.logger.tag(tags)
    end

    def log(level, message, data = {})
      logger.send(level, message, base_log_data.merge(data))
    end
   end
end

DEA::FSD.new