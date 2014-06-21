# UTF-8
require 'eventmachine'
require "steno"
require "steno/core_ext"
require 'json'

module Dea
  class ClientOnce
    class Connector < EM::Connection
      
      def initialize(msg)
        @data = msg
      end
      
      def post_init
     
        send_data "zz" + @data
         
        close_connection_after_writing
         
      end

    def receive_data(data)
        puts "Received #{data.length} bytes , data = #{data}"
    end

    
     
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
         
      end
      
    end
 
  end
end
