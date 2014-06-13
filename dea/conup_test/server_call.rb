
require 'eventmachine'
require "steno"
require "steno/core_ext"
require 'json'
require_relative "../conup/tx_dep_monitor"
require_relative "../conup/tx_event_type"
require_relative "../stats_collect_server"
require "set"
require_relative "./constant"
 

config = {}
config["collect_port"] = Cons::Call_Port
config["collect_ip"] = "192.168.12.34"
instance = nil
@collect_server = Dea::CollectServer.new(config["collect_ip"],config["collect_port"],config,instance)
@collect_server.start








