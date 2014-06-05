# coding: UTF-8

require "eventmachine"
require "steno"
require "steno/core_ext"


module Dea
  module HealthCheck
    class Base
      include ::EM::Deferrable
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
    
    def base_log_data
      { }
    end

    def log(level, message, data = {})
      logger.send(level, message, base_log_data.merge(data))
    end
      def initialize
        setup_callbacks
        @done = false
      end

      def done?
        @done
      end

      private

      def setup_callbacks
        [:callback, :errback].each do |method|
          log(:info,"--- base setup callbacks")
          send(method) { @done = true }
          send(method) { cleanup }
        end
      end
  
      # Can potentially be called more than once, so make it idempotent.
      def cleanup
      end
    end
  end
end
