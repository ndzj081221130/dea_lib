# UTF-8
require 'eventmachine'
require "steno"
require "steno/core_ext"
require 'json'

module Dea
  class ClientSyncClose
    class Connector < EM::Connection
      
      #attr_accessor :data_received
      def initialize(msg)
        @data = msg
      end
      
      def post_init
        send_data "zz" + @data
        #EventMachine::stop # not this
         # close_connection_after_writing
         
      end

    def receive_data(data)
      puts "Received #{data.length} bytes,data = #{data}"
      @data_received = data
      puts @data_received
      close_connection #在接受到消息后，关闭链接？
      EventMachine::stop # bu fang shi yi shi
    end

    # def unbind
      # EventMachine.stop_event_loop 应该也不是这个
    # end
     
    end

    attr_accessor :other_ip
    attr_accessor :other_port
    attr_accessor :message
    
    def initialize(ip,port,msg)
      @other_ip = ip
      @other_port = port
      @message = msg
      EM.run do
        EM.connect(ip, port, Connector,@message) #192.168.12.34
        # EM.stop
      end
      
    end
 
  end
end
