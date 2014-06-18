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
        #EventMachine::stop # not this
         # close_connection_after_writing
         
      end

    def receive_data(data)
      #puts "Received #{data.length} bytes,data = #{data}"
      @data_received = data
      #puts @data_received
      @queue.push(@data_received)
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
    attr_accessor :q
    attr_accessor :response
    def initialize(ip,port,msg)
      @other_ip = ip
      @other_port = port
      @message = msg
      
      EM.run do
        @q = EM::Queue.new
        
        cb = Proc.new do |msg1|
           # puts "sent #{msg1}"
         #   send_data(msg1)
            @response = msg1
            q.pop &cb
          end

        q.pop &cb
    
        EM.connect(ip, port, Connector,@message,q) 
        # EM.stop
        
        
      end
      
    end
 
  end
end
