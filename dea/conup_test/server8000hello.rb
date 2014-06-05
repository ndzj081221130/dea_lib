
require 'eventmachine'
require "steno"
require "steno/core_ext"
require 'json'
require_relative "../conup/tx_dep_monitor"
require_relative "../conup/tx_event_type"
require_relative "../stats_collect_server"
require "set"
require_relative "../config"
require "yaml" 
configY = YAML.load_file("/vagrant/dea_ng/config/dea.yml")

config = Dea::Config.new(configY)

port = Integer(config["collect_port"])
bias = config.bias
new_port = port + bias
instance = nil
collect_server = Dea::CollectServer.new(config["collect_ip"],new_port.to_s,config,instance)
config.bias += 1      
puts config.bias
    
collect_server.start