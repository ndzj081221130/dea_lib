# coding: UTF-8

require "membrane"
require "steno"
require "steno/core_ext"
require "vcap/common"
require "yaml"
require "set"
require "dea/env"
require "dea/utils/event_emitter"
require "dea/health_check/port_open"
require "dea/health_check/state_file_ready"
require "dea/promise"
require "dea/task"
require "dea/stats_collect_server"
module Dea
  class Instance < Task
    include EventEmitter

    STAT_COLLECTION_INTERVAL_SECS = 10

    BIND_MOUNT_MODE_MAP = {
      "ro" =>  ::Warden::Protocol::CreateRequest::BindMount::Mode::RO,
      "rw" =>  ::Warden::Protocol::CreateRequest::BindMount::Mode::RW,
    }

    class State
      BORN     = "BORN"
      STARTING = "STARTING"
      RUNNING  = "RUNNING"
      STOPPING = "STOPPING"
      STOPPED  = "STOPPED"
      CRASHED  = "CRASHED"
      DELETED  = "DELETED"
      RESUMING = "RESUMING"

      def self.from_external(state) # 将外部状态转为大写？
        case state.upcase
        when "BORN"
          BORN
        when "STARTING"
          STARTING
        when "RUNNING"
          RUNNING
        when "STOPPING"
          STOPPING
        when "STOPPED"
          STOPPED
        when "CRASHED"
          CRASHED
        when "DELETED"
          DELETED
        when "RESUMING"
          RESUMING
        else
          raise "Unknown state: #{state}"
        end
      end

      def self.to_external(state) #将内部状态转为字符串
        case state
        when Dea::Instance::State::BORN
          "BORN"
        when Dea::Instance::State::STARTING
          "STARTING"
        when Dea::Instance::State::RUNNING
          "RUNNING"
        when Dea::Instance::State::STOPPING
          "STOPPING"
        when Dea::Instance::State::STOPPED
          "STOPPED"
        when Dea::Instance::State::CRASHED
          "CRASHED"
        when Dea::Instance::State::DELETED
          "DELETED"
        when Dea::Instance::State::RESUMING
          "RESUMING"
        else
          raise "Unknown state: #{state}"
        end
      end
    end

    class Transition < Struct.new(:from, :to) #状态转移？
      def initialize(*args)
        super(*args.map(&:to_s).map(&:downcase))
      end
    end

    class TransitionError < BaseError
      attr_reader :from
      attr_reader :to

      def initialize(from, to = nil)
        @from = from
        @to = to
      end

      def message
        parts = []
        parts << "Cannot transition from %s" % [from.inspect]

        if to
          parts << "to %s" % [to.inspect]
        end

        parts.join(" ")
      end
    end

    def self.translate_attributes(attributes)
      attributes = attributes.dup#数组复制

      attributes["instance_index"]      ||= attributes.delete("index")

      attributes["application_id"]      ||= attributes.delete("droplet").to_s
      attributes["application_version"] ||= attributes.delete("version")
      attributes["application_name"]    ||= attributes.delete("name")
      attributes["application_uris"]    ||= attributes.delete("uris")
      attributes["application_prod"]    ||= attributes.delete("prod")

      attributes["droplet_sha1"]        ||= attributes.delete("sha1")
      attributes["droplet_uri"]         ||= attributes.delete("executableUri")

      # Translate environment to dictionary (it is passed as Array with VAR=VAL)
      env = attributes.delete("env") || []
      attributes["environment"] ||= Hash[env.map do |e|
        pair = e.split("=", 2)
        pair[0] = pair[0].to_s
        pair[1] = pair[1].to_s
        pair
      end]

      attributes
    end

    def self.limits_schema
      Membrane::SchemaParser.parse do
        {
          "mem"  => Fixnum,
          "disk" => Fixnum,
          "fds"  => Fixnum,
        }
      end
    end

    def self.service_schema #DEA绑定的服务？
      Membrane::SchemaParser.parse do
        {
          "name"        => String,
          "label"       => String,
          "vendor"      => String,
          "version"     => String,
          "plan"        => String,
          "credentials" => any,

          # Deprecated fields
          optional("type")        => String,
          optional("tags")        => [String],
          optional("plan_option") => enum(String, nil),
        }
      end
    end

    def self.schema
      limits_schema = self.limits_schema
      service_schema = self.service_schema

      Membrane::SchemaParser.parse do
        {
          # Static attributes (coming from cloud controller):
          "cc_partition"        => String,

          "instance_id"         => String,
          "instance_index"      => Integer,

          "application_id"      => String,
          "application_version" => String,
          "application_name"    => String,
          "application_uris"    => [String],
          "application_prod"    => bool,

          "droplet_sha1"        => String,
          "droplet_uri"         => String,

          optional("runtime_name")   => String,
          optional("runtime_info")   => dict(String, any),
          optional("framework_name") => String,

          # TODO: use proper schema
          "limits"              => limits_schema,
          "environment"         => dict(String, String),
          "services"            => [service_schema],
          optional("flapping")  => bool,

          optional("debug")     => enum(nil, String),
          optional("console")   => enum(nil, bool),

          # private_instance_id is internal id that represents the instance,
          # which is generated by DEA itself. Currently, we broadcast it to
          # all routers. Routers use that as sticky session of the instance.
          "private_instance_id" => String, #private_instance_id是DEA的唯一标识
        }
      end
    end

    # Define an accessor for every attribute with a schema
    self.schema.schemas.each do |key, _|
      define_method(key) do
        attributes[key]
      end
    end

    # Accessors for different types of host/container ports
    [nil, "debug", "console"].each do |type|
      ["host", "container"].each do |side|
        key = ["instance", type, side, "port"].compact.join("_")
        define_method(key) do
          attributes[key]
        end
      end
    end

    def self.define_state_methods(state)
      state_predicate = "#{state.to_s.downcase}?"
      define_method(state_predicate) do
        self.state == state
      end

      state_time = "state_#{state.to_s.downcase}_timestamp"
      define_method(state_time) do
        attributes[state_time]
      end
    end

    # Define predicate methods for querying state
    State.constants.each do |state|
      define_state_methods(State.const_get(state))
    end

    attr_reader :bootstrap
    attr_reader :attributes
    attr_reader :start_timestamp
    attr_reader :used_memory_in_bytes
    attr_reader :used_disk_in_bytes
    attr_reader :computed_pcpu    # See `man ps`
    attr_reader :cpu_samples
    
    attr_accessor :stats #TODO this is added by zhang
    attr_accessor :oldRootTxs #TODO testing . added by zhang
    attr_accessor :new_port
    attr_accessor :exit_status
    attr_accessor :exit_description

    def initialize(bootstrap, attributes)
      super(bootstrap.config)
      @bootstrap = bootstrap
      @stats = "NORMAL"
      @oldRootTxs = Set.new
      puts "{instance initialize} #{bootstrap.config.bias}"
          port = Integer(bootstrap.config["collect_port"])
          bias = bootstrap.config.bias
          @new_port = port + bias
          bootstrap.config.bias += 1
          
      @attributes = attributes.dup
      @attributes["application_uris"] ||= []

      # Generate unique ID
      @attributes["instance_id"] ||= VCAP.secure_uuid

      # Contatenate 2 UUIDs to generate a 32 chars long private_instance_id
      @attributes["private_instance_id"] ||= VCAP.secure_uuid + VCAP.secure_uuid

      self.state = State::BORN

      # Assume non-production app when not specified
      @attributes["application_prod"] ||= false

      @used_memory_in_bytes  = 0
      @used_disk_in_bytes    = 0
      @computed_pcpu         = 0
      @cpu_samples           = []
      @exit_status           = -1
      @exit_description      = ""
    end

    def setup
      setup_stat_collector
      setup_link
      setup_crash_handler
    end

    # TODO: Fill in once start is hooked up
    def flapping?
      false
    end

    def memory_limit_in_bytes
     
     # logger.debug("zhang come from cc #{limits["mem"]}")
      limits["mem"].to_i * 1024 * 1024
    end

    def disk_limit_in_bytes
      limits["disk"].to_i * 1024 * 1024
    end

    def file_descriptor_limit
      limits["fds"].to_i
    end

    def production_app?
      attributes["application_prod"]
    end

    def instance_path_available? #只有在running和crash状态下，才会存储instance
      state == State::RUNNING || state == State::CRASHED
    end

    def instance_path
      attributes["instance_path"] ||=
        begin
          if !instance_path_available? || attributes["warden_container_path"].nil?
            raise "Instance path unavailable"
          end

          File.expand_path(container_relative_path(attributes["warden_container_path"]))
        end
    end

    def paths_to_bind
      [droplet.droplet_dirname]
    end

    def validate
      self.class.schema.validate(@attributes)
    end

    def state
      attributes["state"]
    end

    def state=(state)
      transition = Transition.new(attributes["state"], state)

      attributes["state"] = state
      attributes["state_timestamp"] = Time.now.to_f

      state_time = "state_#{state.to_s.downcase}_timestamp"
      attributes[state_time] = Time.now.to_f

      emit(transition)#emit???
      
    end

    
    
    def state_timestamp
      attributes["state_timestamp"]
    end

    def droplet #根据sha1返回注册表中的droplet
      bootstrap.droplet_registry[droplet_sha1]
    end

    def application_uris=(uris)
      attributes["application_uris"] = uris
      nil
    end

    def to_s
      "Instance(id=%s, idx=%s, app_id=%s)" % [instance_id.slice(0, 4),
                                             instance_index, application_id]
    end

    def promise_state(from, to = nil)
      promise_state = Promise.new do
        if !Array(from).include?(state)
          promise_state.fail(TransitionError.new(state, to))
        else
          if to
            self.state = to
          end

          promise_state.deliver
        end
      end
    end

    def promise_droplet_download
      promise_droplet_download = Promise.new do
        droplet.download(droplet_uri) do |error|
          if error
            promise_droplet_download.fail(error)
          else
            promise_droplet_download.deliver
          end
        end
      end
    end

    def promise_setup_network
      Promise.new do |p|
        net_in = lambda do
          request = ::Warden::Protocol::NetInRequest.new
          request.handle = @attributes["warden_handle"]
          promise_warden_call(:app, request).resolve
        end

        response = net_in.call
        attributes["instance_host_port"]      = response.host_port
        attributes["instance_container_port"] = response.container_port

        response = net_in.call
        attributes["instance_console_host_port"]      = response.host_port
        attributes["instance_console_container_port"] = response.container_port

        if attributes["debug"]
          response = net_in.call
          attributes["instance_debug_host_port"]      = response.host_port
          attributes["instance_debug_container_port"] = response.container_port
        end

        p.deliver
      end
    end

    def promise_setup_environment
      Promise.new do |p|
        script = "cd / && mkdir -p home/vcap/app && chown vcap:vcap home/vcap/app && ln -s home/vcap/app /app"
        promise_warden_run(:app, script, true).resolve

        p.deliver
      end
    end

    def promise_extract_droplet #解压缩droplet包
      Promise.new do |p|
        script = "cd /home/vcap/ && tar zxf #{droplet.droplet_path}"

        promise_warden_run(:app, script).resolve

        p.deliver
      end
    end

    def promise_start #启动start脚本
      Promise.new do |p|
        script = []

        script << "umask 077"

        env = Env.new(self)
        env.env.each do |(key, value)|
          script << "export %s=%s" % [key, value]
        end

        startup = "./startup"

        # Pass port to `startup` if we have one
        if self.instance_host_port
          startup << " -p %d" % self.instance_host_port
        end

        script << startup
        script << "exit"

        request = ::Warden::Protocol::SpawnRequest.new
        request.handle = attributes["warden_handle"]
        request.script = script.join("\n")

        request.rlimits = ::Warden::Protocol::ResourceLimits.new
        request.rlimits.nofile = self.file_descriptor_limit
        request.rlimits.nproc = 512

        response = promise_warden_call(:app, request).resolve

        attributes["warden_job_id"] = response.job_id

        p.deliver
      end
    end

    def promise_container_info #获取容器的info，
      Promise.new do |p|
        handle = @attributes["warden_handle"]
        request = ::Warden::Protocol::InfoRequest.new(:handle => handle)

        response = promise_warden_call(:info, request).resolve
        @attributes["warden_container_path"] = response.container_path
        @attributes["warden_host_ip"] = response.host_ip

        p.deliver(response)
      end
    end

    def promise_exec_hook_script(key)
      Promise.new do |p|
        if bootstrap.config['hooks'] && bootstrap.config['hooks'][key]
          script_path = bootstrap.config['hooks'][key]
          if File.exist?(script_path)
            script = []
            script << "umask 077"
            env = Env.new(self)
            env.env.each do |k, v|
              script << "export %s=%s" % [k, v]
            end
            script << File.read(script_path)
            script << "exit"
            promise_warden_run(:app, script.join("\n")).resolve
          else
            log(:warn, "droplet.hook-script.missing", :hook => key, :script_path => script_path)
          end
        end
        p.deliver
      end
    end

    def start(&callback)
      p = Promise.new do
        log(:info, "--droplet.starting, called 2ci???")

        promise_state(State::BORN, State::STARTING).resolve

        # Concurrently download droplet and setup container
        [
          promise_droplet,
          promise_container
        ].each(&:run).each(&:resolve)

        [
          promise_setup_network,
          promise_extract_droplet,
          promise_exec_hook_script('before_start'),
          promise_start
        ].each(&:resolve)

        on(Transition.new(:starting, :crashed)) do
          cancel_health_check
        end
        #先进行一次link，如果此时instance已经crash了，那么之后就不需要进行health check了。
        # Fire off link so that the health check can be cancelled when the
        # instance crashes before the health check completes.
        link

        if promise_health_check.resolve
          log(:info, "droplet.healthy") #there is an other link after this?
          promise_state(State::STARTING, State::RUNNING).resolve

          promise_exec_hook_script('after_start').resolve
        else
          log(:warn, "droplet.unhealthy")
          p.fail("App instance failed health check")
        end

        p.deliver
      end

      resolve(p, "start instance") do |error, _| # this is log start instance 这里应该是接受到了来自cc的start请求，那么Comp具体的运行实例就确定了。
        if error
          # An error occurred while starting, mark as crashed
          self.exit_description = error.message
          self.state = State::CRASHED
          log(:warn, " error after start instance")
          log(:info, error.message)
          
          if @config.bias >= 1
            @config.bias -= 1
          end
          
        else
          puts "start instance succeed, start a collect_server here on #{@new_port}, bias = #{@config.bias} , "
          
      
          @collect_server = Dea::CollectServer.new(@config["collect_ip"],
                                 @new_port.to_s,
                                 @config,
                                 
                                 self)
           
         
          @collect_server.start # 如何记录下？？？ 在collect_server内部记录吧。
          
          
          
        end
        
        log(:info , "out if , error !!!")
        callback.call(error) unless callback.nil?
      end
    end

    def promise_container
      Promise.new do |p|
        promise_create_container.resolve
        promise_setup_network.resolve
        promise_limit_disk.resolve
        promise_limit_memory.resolve
        promise_setup_environment.resolve

        p.deliver
      end
    end

    def promise_droplet
      Promise.new do |p|
        if !droplet.droplet_exist?
          log(:info, " droplet.download.starting")
          start = Time.now
          promise_droplet_download.resolve
          log(:info, " droplet.download.finished", :took => Time.now - start)
        else
          log(:info, " droplet.download.skipped")
        end

        p.deliver
      end
    end

    def stop(&callback)
      p = Promise.new do
        log(:info, "droplet.stopping")

        promise_exec_hook_script('before_stop').resolve

        promise_state(State::RUNNING, State::STOPPING).resolve

        promise_exec_hook_script('after_stop').resolve

        promise_stop.resolve

        promise_state(State::STOPPING, State::STOPPED).resolve

        p.deliver
      end

      resolve(p, "stop instance") do |error, _|
        callback.call(error) unless callback.nil?
      end
    end

    def promise_copy_out
      Promise.new do |p|
        new_instance_path = File.join(config.crashes_path, instance_id)
        new_instance_path = File.expand_path(new_instance_path)
        copy_out_request("/home/vcap/", new_instance_path)

        attributes["instance_path"] = new_instance_path

        p.deliver
      end
    end

    def setup_crash_handler
      # Resuming to crashed state
      on(Transition.new(:resuming, :crashed)) do
        crash_handler
      end

      # On crash
      on(Transition.new(:starting, :crashed)) do
        crash_handler
      end

      # On crash
      on(Transition.new(:running, :crashed)) do
        crash_handler
      end
    end

    def promise_crash_handler
      Promise.new do |p|
        if attributes["warden_handle"]
          promise_copy_out.resolve
          log(:debug," destroy_place 1 : crash handler")
          promise_destroy.resolve

          close_warden_connections #关闭与warden之间的连接
        end

        p.deliver
      end
    end

    def crash_handler(&callback)
      Promise.resolve(promise_crash_handler) do |error, _|
        if error
          log(
            :warn, "droplet.crash-handler.error",
            :error => error, :backtrace => error.backtrace)
        end

        callback.call(error) unless callback.nil?
      end
    end

    def setup_stat_collector
      on(Transition.new(:resuming, :running)) do
        start_stat_collector #开始收集stat？
      end

      on(Transition.new(:starting, :running)) do
        start_stat_collector
      end

      on(Transition.new(:running, :stopping)) do
        stop_stat_collector
      end

      on(Transition.new(:running, :crashed)) do
        stop_stat_collector
      end
    end

    def start_stat_collector
      @run_stat_collector = true

      run_stat_collector
    end

    def stop_stat_collector
      @run_stat_collector = false

      if @run_stat_collector_timer
        @run_stat_collector_timer.cancel
        @run_stat_collector_timer = nil
      end
    end

    def stat_collection_interval_secs
      STAT_COLLECTION_INTERVAL_SECS #每10s，收集一次状态
    end

    def run_stat_collector
      Promise.resolve(promise_collect_stats) do
        if @run_stat_collector
          @run_stat_collector_timer =
            ::EM::Timer.new(stat_collection_interval_secs) do
              run_stat_collector
            end
        end
      end
    end

    def promise_collect_stats
      Promise.new do |p|
        begin
          info_resp = promise_container_info.resolve
        rescue => error
          log(
            :error, "droplet.container-info-retrieval.failed",
            :error => error, :backtrace => error.backtrace)

          raise
        end

        @used_memory_in_bytes = info_resp.memory_stat.rss * 1024

        @used_disk_in_bytes = info_resp.disk_stat.bytes_used

        now = Time.now

        @cpu_samples << {
          :timestamp_ns => now.to_i * 1_000_000_000 + now.nsec,
          :ns_used      => info_resp.cpu_stat.usage,
        }

        @cpu_samples.shift if @cpu_samples.size > 2

        if @cpu_samples.size == 2
          used = @cpu_samples[1][:ns_used] - @cpu_samples[0][:ns_used]
          elapsed = @cpu_samples[1][:timestamp_ns] - @cpu_samples[0][:timestamp_ns]

          if elapsed > 0
            @computed_pcpu = used.to_f / elapsed
          end
        end

        p.deliver
      end
    end

    def setup_link
      # Resuming to running state
      on(Transition.new(:resuming, :running)) do
        log(:info,"second link? in setup_link")
        link
      end
    end

    def promise_link
      Promise.new do |p|
        request = ::Warden::Protocol::LinkRequest.new
        request.handle = attributes["warden_handle"]
        request.job_id = attributes["warden_job_id"]
        log(:info,"before promise_warden_call_with_retry")
        response = promise_warden_call_with_retry(:link, request).resolve #this should be block here?

        log(:info, "droplet.warden.link.completed", :exit_status => response.exit_status)
    
        p.deliver(response)
      end
    end

    def link(&callback)
      Promise.resolve(promise_link) do |error, link_response|
        log(:info,"in link method")
        if error
          self.exit_status = -1
          self.exit_description = "unknown"
          log(:info,"error in link")
        else
          self.exit_status = link_response.exit_status
          self.exit_description = determine_exit_description(link_response)
        end

        case self.state
        when State::STARTING
          self.state = State::CRASHED
        when State::RUNNING
          uptime = Time.now - attributes["state_running_timestamp"]
          log(:info, "droplet.instance.uptime", :uptime => uptime)
#edited_by_zhang
          self.state = State::CRASHED
        else
          # Linking likely completed because of stop
        end

        callback.call(error) unless callback.nil?
      end
    end

    def promise_read_instance_manifest(container_path)
      Promise.new do |p|
        if container_path.nil?
          p.deliver({})
          next
        end

        manifest_path = container_relative_path(container_path, "droplet.yaml")
        if !File.exist?(manifest_path)
          p.deliver({})
        else
          manifest = YAML.load_file(manifest_path)
          p.deliver(manifest)
        end
      end
    end

    def promise_port_open(port)
      Promise.new do |p|
        host = bootstrap.local_ip

        log(:debug, " ---droplet.healthcheck.port ", :host => host, :port => port)

        @health_check = Dea::HealthCheck::PortOpen.new(host, port) do |hc|
          hc.callback { 
            log(:debug,"--- healthCheck true")
            
            p.deliver(true) 
            }

          hc.errback  { 
            log(:debug,"--- healthCheck false")
            p.deliver(false) }

          if attributes["debug"] != "suspend"
            hc.timeout(60)
          end
        end
      end
    end

    def promise_state_file_ready(path)
      Promise.new do |p|
        log(:debug, "droplet.healthcheck.file", :path => path)

        @health_check = Dea::HealthCheck::StateFileReady.new(path) do |hc|
          hc.callback { p.deliver(true) }

          hc.errback { p.deliver(false) }

          if attributes["debug"] != "suspend"
            hc.timeout(60 * 5)
          end
        end
      end
    end

    def cancel_health_check
      if @health_check
        @health_check.fail
        @health_check = nil
      end
    end

    def promise_health_check
      Promise.new do |p|
        info = promise_container_info.resolve

        manifest = promise_read_instance_manifest(info.container_path).resolve

        if manifest["state_file"]
          log(:info, "--- promise_health_check if manifest[]")
          manifest_path = container_relative_path(info.container_path, manifest["state_file"])
          p.deliver(promise_state_file_ready(manifest_path).resolve)
        elsif !application_uris.empty?
        #  log(:info, "--- good:promise_health_check elsif !application_uris.empty?")
          p.deliver(promise_port_open(instance_host_port).resolve)
         # p.deliver(true)
        else
          log(:info, "--- promise_health_check else")
          p.deliver(true)
         end
      end
    end

    private

    def determine_exit_description(link_response)
      info = link_response.info
      return "cannot be determined" unless info

      if info.events && info.events.include?("oom")
        return "out of memory"
      end

      "app instance exited"
    end

    def container_relative_path(root, *parts)
      # This can be removed once warden's wsh branch is merged to master
      if File.directory?(File.join(root, "rootfs"))
        return File.join(root, "rootfs", "home", "vcap", *parts)
      end

      # New path
      File.join(root, "tmp", "rootfs", "home", "vcap", *parts)
    end

    def logger
      tags = {
        "instance_id"         => instance_id,
        "instance_index"      => instance_index,
        "application_id"      => application_id,
        "application_version" => application_version,
        "application_name"    => application_name,
      }

      @logger ||= self.class.logger.tag(tags)
    end

    def log(level, message, data = {})
      logger.send(level, message, base_log_data.merge(data))
    end

    def base_log_data
      { :attributes => @attributes }
    end
  end
end
