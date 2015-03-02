# UTF-8
require 'eventmachine'
require "steno"
require "steno/core_ext"
require 'json'

module Dea
  class ClientSync
    class Connector < EM::Connection
      
      #attr_accessor :data_received
      def initialize(msg)
        @data = msg
      end
      
      def post_init
        send_data "zz" + @data
         
         
      end

    def receive_data(data)
       
      @data_received = data
      
      close_connection #在接受到消息后，关闭链接？
      # bu fang shi yi shi
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
