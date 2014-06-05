require "warden/config"
require "warden/container"
require "warden/errors"
require "warden/event_emitter"
require "warden/network"
require "warden/pool/network"
require "warden/pool/port"
require "warden/pool/uid"

require "eventmachine"
require "fiber"
require "fileutils"
require "set"
require "steno"
require "steno/core_ext"

class ClientConnection < ::EM::Connection

      
      CRLF = "\r\n"

      include EventEmitter

      def post_init
        @draining = false
        @current_request = nil
        @blocked = false
        @closing = false
        @requests = []
        @buffer = Protocol::Buffer.new
        @bound = true

        Server.drainer.register_connection(self)
      end

      def bound?
        @bound
      end

      def unbind
        @bound = false

        f = Fiber.new { emit(:close) }
        f.resume

        Server.drainer.unregister_connection(self)
      end

      def close
        close_connection_after_writing
        @closing = true
      end

      def closing?
        !! @closing
      end

      def drain
        logger.debug("Draining connection on: #{self}")

        @draining = true

        
      end

      def send_response(obj)
        logger.debug2(obj.inspect)

        data = obj.wrap.encode.to_s
        send_data data.length.to_s + "\r\n"
        send_data data + "\r\n"
      end

      def send_error(err)
        send_response Protocol::ErrorResponse.new(:message => err.message)
      end

      def receive_data(data)
        @buffer << data
        @buffer.each_request do |request|
          begin
            receive_request(request)
          rescue => e
            close_connection_after_writing
            logger.warn("Disconnected client after error")
            logger.log_exception(e)
          end
        end
      end

      def receive_request(req = nil)
        @requests << req if req

        # Don't start new request when old one hasn't finished, or the
        # connection is about to be closed.
        return if @blocked or @closing

        request = @requests.shift

        return if request.nil?

        logger.debug2(request.inspect)

        f = Fiber.new {
          begin
            @blocked = true
            @current_request = request
            process(request)

          ensure
            @current_request = nil
            @blocked = false

            if @draining
              logger.debug("Finished processing request, closing #{self}")
              close
            else
              # Resume processing the input buffer
              ::EM.next_tick { receive_request }
            end
          end
        }

        f.resume
      end

      def process(request)
        case request
        when Protocol::PingRequest
          response = request.create_response
          send_response(response)

        when Protocol::ListRequest
          response = request.create_response
          response.handles = Server.container_klass.registry.keys.map(&:to_s)
          send_response(response)

        when Protocol::EchoRequest
          response = request.create_response
          response.message = request.message
          send_response(response)

        when Protocol::CreateRequest
          container = Server.container_klass.new
          container.register_connection(self)
          response = container.dispatch(request)
          send_response(response)

        else
          if request.respond_to?(:handle)
            container = find_container(request.handle)
            process_container_request(request, container)
          else
            raise WardenError.new("Unknown request: #{request.class.name.split("::").last}")
          end
        end
      rescue WardenError => e
        send_error(e)
      rescue => e
        logger.log_exception(e)
        send_error(e)
      end

      def process_container_request(request, container)
        case request
        when Protocol::StopRequest
          if request.background
            # Dispatch request out of band when the `background` flag is set
            ::EM.next_tick do
              f = Fiber.new do
                # Ignore response
                container.dispatch(request)
              end

              f.resume
            end

            response = request.create_response
            send_response(response)
          else
            response = container.dispatch(request)
            send_response(response)
          end

        when Protocol::StreamRequest
          response = container.dispatch(request) do |name, data|
            break if !bound?

            response = request.create_response
            response.name = name
            response.data = data
            send_response(response)
          end

          # Terminate by sending exit status only.
          send_response(response)
        else
          response = container.dispatch(request)
          send_response(response)
        end
      end

      protected

      def find_container(handle)
        Server.container_klass.registry[handle].tap do |container|
          raise WardenError.new("unknown handle") if container.nil?

          # Let the container know that this connection references it
          container.register_connection(self)
        end
      end
end
