require 'machines/etc/notify'

module Machines
  module Timedomain

    # The Sample class will notify all listeners to the #on_sample function 
    # at even intervals
    class Sampler
      extend Notify

      attr_reader :sample_time
      notify :sample

      def initialize(sample_time)
        @timer = nil
        @sample_time = Analog.to_analog sample_time
        @sample_time.on_change do
          stop
          start
        end
      end

      def running?
        !!@timer
      end

      def start
        unless @timer
          @timer = EventMachine::PeriodicTimer.new @sample_time.v { notify_sample }
        end
      end

      def stop
        if @timer
          @timer.cancel
          @timer = nil
        end
      end

    end
  end
end





