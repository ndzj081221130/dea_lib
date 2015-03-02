
require 'eventmachine'
require "steno"
require "steno/core_ext"
require 'json'
require_relative "../conup/tx_dep_monitor"
# require_relative "../conup/datamodel/tx_event_type"
require_relative "../stats_collect_server"
require_relative "./constant"
require "set"

 

config = {}
config["collect_port"] = Cons::PaPa_Port
config["collect_ip"] = "192.168.12.34"
instance = nil
@collect_server = Dea::MessageServer.new(config["collect_ip"],config["collect_port"],config,instance)
@collect_server.start








