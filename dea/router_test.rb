require_relative "./config"
require "nats/client"
require "eventmachine"

module Dea
  class RouterClient
    class Bootstrap
      def initialize(config = {})
        @config = Config.new(config)
      end
    end
    class Nats
     attr_reader :bootstrap
    # attr_reader :config
    attr_reader :sids

    def initialize#(bootstrap, config)
       @bootstrap = Bootstrap.new # bootstrap
      # @config    = config
      @sids      = {}
      @client    = nil
      
      start()
    end

    def start
      # subscribe("healthmanager.start") do |message|
        # bootstrap.handle_health_manager_start(message)
      # end

      # subscribe("router.start") do |message|
        # bootstrap.handle_router_start(message)
        
        # instance =  Dea::Instance.new(bootstrap, {"application_id" => 1, "warden_handle" => "handle1"})
        # 
        
      # end

      # subscribe("dea.status") do |message|
        # bootstrap.handle_dea_status(message)
      # end
# 
      # subscribe("dea.#{bootstrap.uuid}.start") do |message|
        # bootstrap.handle_dea_directed_start(message)
      # end
# 
      # subscribe("dea.stop") do |message|
        # bootstrap.handle_dea_stop(message)
      # end
# 
      # subscribe("dea.discover") do |message|
        # bootstrap.handle_dea_discover(message)
      # end
# 
      # subscribe("dea.update") do |message|
        # bootstrap.handle_dea_update(message)
      # end
# 
      # subscribe("dea.find.droplet") do |message|
        # bootstrap.handle_dea_find_droplet(message)
      # end
# 
      # subscribe("droplet.status") do |message|
        # bootstrap.handle_droplet_status(message)
      # end
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
         puts "Received on #{subject.inspect}: #{message.data.inspect}"
          yield message
        rescue => e
          # logger.error 
          puts "Error \"#{e}\" raised while processing #{subject.inspect}: #{message ? message.data.inspect : raw_data }"
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
      # logger.info "Connecting to NATS on #{config["nats_uri"]}" = 
      # NATS waits by default for 2s before attempting to reconnect, so a million reconnect attempts would
      # save us from a NATS out age for approximately 23 days - which is large enough.
      ::NATS.connect(:uri => "nats://localhost:4222/", :max_reconnect_attempts => 999999)
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
        nats.publish(subject, data)
      end
    end

    private

    # def logger
      # @logger ||= self.class.logger
    # end
  end
    # attr_reader :bootstrap

    # def initialize(bootstrap)
      # @bootstrap = bootstrap
    # end
    attr_reader :nats
    def initialize
      setup_nats
    end
    
    def setup_nats
      @nats = Nats.new 
    end
    
     def start_nats
      nats.start
      end
    def register_directory_server(host, port, uri)
      req = generate_directory_server_request(host, port, uri)
      nats.publish("router.register", req)
    end

    def unregister_directory_server(host, port, uri)
      req = generate_directory_server_request(host, port, uri)
      nats.publish("router.unregister", req)
    end

    def register_instance(instance, opts = {})
      puts "register_instance"
      req = generate_instance_request(instance, opts)
      nats.publish("router.register", req)
    end

    def unregister_instance(instance, opts = {})
      req = generate_instance_request(instance, opts)
      nats.publish("router.unregister", req)
    end

    private

    # Same format is used for both registration and unregistration
    def generate_instance_request(instance, opts = {})
     uris = {}
     uris["uris"] = "973694b07429d91edf8203559a234ae8.192.168.12.34.xip.io"
     # uuid = 
     # arr = Array.new
     json = {"uris" => ["973694b07429d91edf8203559a234ae8.192.168.12.34.xip.io"]}
      { "dea"  => "bootstrap.uuid",
        "app"  => "instance.application_id",
         "uris" => json["uris"],
        "host" => "192.168.12.34",
        "port" => 61015,
        "tags" => { "component" => "dea-{bootstrap.config}" },
        "private_instance_id" => "84ef1bb842d65eff893fbb1a59723ffa5ebe87b5e0db6de830299d05c4b5d664",
      }
    end

# {"timestamp":1394542126.811982155,"process_id":16327,"source":"router.global","log_level":"debug",
  # "message":"zhang:router.register: Received message",
  # "data":{"message":{"host":"192.168.12.34","port":61015,"uris":["tuscany.192.168.12.34.xip.io"],
    # "tags":{"component":"dea-1"},
    # "app":"0b883ed9-9e85-4d78-9b51-9da9dbc851c5",
    # "private_instance_id":"84ef1bb842d65eff893fbb1a59723ffa5ebe87b5e0db6de830299d05c4b5d664"}}}
    # Same format is used for both registration and unregistration
    def generate_directory_server_request(host, port, uri)
      { "host" => host,
        "port" => port,
        "uris" => [uri],
        "tags" => {},
      }
    end
  end
end
EM.epoll

EM.run do
  # bootstrap.setup
  # bootstrap.start
  router_client = Dea::RouterClient.new 
router_client.register_instance("instance")
end
# router_client.register_directory_server(
        # local_ip,
        # directory_server_v2.port,
        # directory_server_v2.external_hostname
      # )
# router_client.register_instance(instance) 