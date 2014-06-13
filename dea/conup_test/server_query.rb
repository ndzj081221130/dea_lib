
require 'eventmachine'
require "steno"
require "steno/core_ext"
require 'json'
require_relative "../conup/tx_dep_monitor"
require_relative "../conup/tx_event_type"
require_relative "../query_server"
require "set"
require_relative "../config"
require "yaml" 
configY = YAML.load_file("/vagrant/dea_ng/config/dea.yml")

config = Dea::Config.new(configY)

port = Integer(config["query_port"])

 
collect_server = Dea::QueryServer.new(config["collect_ip"],port,config)
 
    
collect_server.start