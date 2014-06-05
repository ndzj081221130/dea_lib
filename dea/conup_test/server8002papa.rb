
require 'eventmachine'
require "steno"
require "steno/core_ext"
require 'json'
require_relative "../conup/tx_dep_monitor"
require_relative "../conup/tx_event_type"
require_relative "../stats_collect_server"
require "set"

 

config = {}
config["collect_port"] = 8002
config["collect_ip"] = "192.168.12.34"
instance = nil
@collect_server = Dea::CollectServer.new(config["collect_ip"],config["collect_port"],config,instance)
@collect_server.start








