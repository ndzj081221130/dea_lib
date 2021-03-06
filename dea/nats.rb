# coding: UTF-8

require "steno"
require "steno/core_ext"
require "nats/client"

module Dea
  class Nats
    attr_reader :bootstrap
    attr_reader :config
    attr_reader :sids

    def initialize(bootstrap, config)
      @bootstrap = bootstrap
      @config    = config
      @sids      = {}
      @client    = nil
    end

    def start
      subscribe("healthmanager.start") do |message|
        bootstrap.handle_health_manager_start(message)
      end
      
      subscribe("router.remote") do |message|
        bootstrap.handle_remote_msg(message)        
      end
      
      subscribe("router.start") do |message|
        
        # puts "nats : router.start message= #{message}"
        bootstrap.handle_router_start(message)
      end

      subscribe("dea.status") do |message|
        bootstrap.handle_dea_status(message)
      end

      subscribe("dea.#{bootstrap.uuid}.start") do |message|
        bootstrap.handle_dea_directed_start(message)
      end

      subscribe("dea.stop") do |message|
        bootstrap.handle_dea_stop(message)
      end

      subscribe("dea.discover") do |message|
        bootstrap.handle_dea_discover(message)
      end

      subscribe("dea.update") do |message|
        bootstrap.handle_dea_update(message)
      end

      subscribe("dea.find.droplet") do |message|
        bootstrap.handle_dea_find_droplet(message)
      end

      subscribe("droplet.status") do |message|
        bootstrap.handle_droplet_status(message)
      end
    end

    def stop
      @sids.each { |_, sid| client.unsubscribe(sid) }
      @sids = {}
    end

    def publish(subject, data)
      client.publish(subject, Yajl::Encoder.encode(data))
    end

    def subscribe(subject, opts={})
      # Do not track subscription option is used with responders
      # since we want them to be responsible for subscribe/unsubscribe.
      do_not_track_subscription = opts.delete(:do_not_track_subscription)

      sid = client.subscribe(subject, opts) do |raw_data, respond_to|
        begin
          message = Message.decode(self, subject, raw_data, respond_to)
          logger.debug "Received on #{subject.inspect}: #{message.data.inspect}"
          #logger.debug "raw_data = #{raw_data},respond_to = #{respond_to}}"
          # puts respond_to == ""
          # puts respond_to == nil
          yield message
        rescue => e
          logger.error "Error \"#{e}\" raised while processing #{subject.inspect}: #{message ? message.data.inspect : raw_data }"
        end
      end

      @sids[subject] = sid unless do_not_track_subscription
      sid
    end

    def unsubscribe(sid)
      client.unsubscribe(sid)
    end

    def client
      @client ||= create_nats_client
    end

    def create_nats_client
      logger.info "Connecting to NATS on #{config["nats_uri"]}"
      # NATS waits by default for 2s before attempting to reconnect, so a million reconnect attempts would
      # save us from a NATS out age for approximately 23 days - which is large enough.
      ::NATS.connect(:uri => config["nats_uri"], :max_reconnect_attempts => 999999)
    end

    class Message
      def self.decode(nats, subject, raw_data, respond_to)
        data = Yajl::Parser.parse(raw_data)
        new(nats, subject, data, respond_to)
      end

      attr_reader :nats
      attr_reader :subject
      attr_reader :data
      attr_reader :respond_to

      def initialize(nats, subject, data, respond_to)
        @nats       = nats
        @subject    = subject
        @data       = data
        @respond_to = respond_to
      end

      def respond(data)
        message = response(data)
        message.publish
      end

      def response(data)
        self.class.new(nats, respond_to, data, nil)
      end

      def publish
        # puts "subject = #{subject}"
        # puts "data = #{data}"
        nats.publish(subject, data)
      end
    end

    private

    def logger
      @logger ||= self.class.logger
    end
  end
end
