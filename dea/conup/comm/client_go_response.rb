# UTF-8
require 'eventmachine'
require "steno"
require "steno/core_ext"
require 'json'

module Dea
  class ClientGoResponse
    class Connector < EM::Connection
      
      attr_accessor :queue
      def initialize(msg,q)
        @data = msg
        @queue = q
      end
      
      def post_init
        send_data   @data                  
      end

    def receive_data(data)
       
      @data_received = data
      
      @queue.push(@data_received)
      
      puts "reved #{data}"
      close_connection #在接受到消息后，关闭链接？
      #EventMachine::stop # bu fang shi yi shi,这个在用户通信时，要关掉，但是放在stats_server不能。
      puts "after close conn"
    end

   
     
    end

    attr_accessor :other_ip
    attr_accessor :other_port
    attr_accessor :message
    attr_accessor :q
    attr_accessor :response
    def initialize(ip,port,msg)
      @other_ip = ip
      @other_port = port
      @message = msg
      
      EM.run do
        @q = EM::Queue.new
        
        cb = Proc.new do |msg1|
           puts "?? #{msg1}"
            @response = msg1
            q.pop &cb
          end

        q.pop &cb
    
        EM.connect(ip, port, Connector,@message,q) 
       
        
        
      end
      
    end
 
  end
end
