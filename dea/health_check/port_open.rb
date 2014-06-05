# coding: UTF-8

require "dea/health_check/base"
require "steno"
require "steno/core_ext"

module Dea
  module HealthCheck
    class PortOpen < ::Dea::HealthCheck::Base

      class ConnectionNotifier < ::EM::Connection

        attr_reader :deferrable

        def initialize(deferrable)
          super

          @connection_completed = false

          @deferrable = deferrable
        end

        def connection_completed
          @connection_completed = true

          deferrable.succeed
        end

        def unbind
          # ECONNREFUSED, ECONNRESET, etc.
         # log(:debug,"unbind")
          deferrable.mark_failure unless @connection_completed
        end
      end

      attr_reader :host
      attr_reader :port


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
     def base_log_data
      { }
    end
    
      def initialize(host, port, retry_interval_secs = 0.5)
        super()

        @host  = host
        @port  = port
        @timer = nil
        @retry_interval_secs = retry_interval_secs
        log(:debug, "--- initialize before yield host = #{host} , port = #{port}",:host=>@host, :port=>@port)
        yield self if block_given?

       # log(:debug, "--- initialize after yield ",:host=>@host, :port=>@port)
        ::EM.next_tick { attempt_connect }
      end

      def mark_failure
        @timer = ::EM::Timer.new(@retry_interval_secs) { attempt_connect }
      end

      private

      def attempt_connect
        if !done?
          #log(:debug,"--- attempt_connect")
          @conn = ::EM.connect(host, port, ConnectionNotifier, self)
        end
      end

      def cleanup
        @conn.close_connection

        if @timer
          @timer.cancel
          @timer = nil
        end
      end
    end
  end
end
