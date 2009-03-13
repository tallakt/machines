module Machines
  module IO
    module IOAccess
      io_buffer = {}

      def di(address)
        buffered_or_new address { ValSignal.new }
      end

      def do(address)
        buffered_or_new address { ValSignal.new }
      end

      def ai(address)
        # TODO
        nil
      end

      def ao(address)
        # TODO
        nil
      end

      private

      def buffered_or_new(address) do
        result = io_buffer[address]
        unless result 
          result = yield
          io_buffer[address] = result
        end
        result
      end
    end
  end
end


