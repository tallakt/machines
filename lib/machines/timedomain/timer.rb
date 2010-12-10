require 'eventmachine'
require 'machines/etc/notify'

module Machines
  module Timedomain
    class Timer
      extend Notify

      notify :finish
      alias :at_end :on_finish

      def initialize(time)
        @time = time
        @start_time = nil
        @em_timer = nil
        on_finish { yield } if block_given?
      end

      def time=(t)
        # analog signals
        @time = Analog.to_analog t
        t.on_change { handle_time_change if @time == t }
        handle_time_change
      end

      def time
        @time
      end

      def elapsed
        @start_time && (Time.now - @start_time)
      end

      def start
        reset
        @start_time = Time.now
        do_wait
      end

      def reset
        @start_time = nil
        @em_timer.cancel if em_timer
        @em_timer = nil
      end

      def active?
        @start_time
      end

      def idle?
        not active?
      end

      private 

      def handle_time_change
        if @em_timer
          @em_timer.cancel
          @em_timer = nil
          do_wait
        end
      end

      def do_wait
        delay = @time.v - elapsed
        if delay > 0.0
          @em_timer = EventMachine::Timer.new(@time - @start_time) do
            @start_time = @em_timer = nil
            notify_finish
          end
        else
          EventMachine::next_tick { notify_finish }
        end
      end
    end
  end
end




