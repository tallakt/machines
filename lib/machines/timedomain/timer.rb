require 'machines/timedomain/scheduler'
require 'machines/etc/notify'

module Machines
  module TimeDomain
    class Timer
      extend Notify

      notify :finish
      alias :at_end :on_finish

      def initialize(time)
        @time = time
        @start_time = nil
        @listeners = []
        on_finish { yield } if block_given?
      end

      def time=(t)
        # todo support analog signals
        @time = t
        if @start_time
          Scheduler.current.cancel self
          do_wait
        end
      end

      def time
        @time
      end

      def elapsed
        if @start_time
          Scheduler.current.now - @start_time
        else
          nil
        end
      end

      def start
        @start_time = Scheduler.current.now
        do_wait
      end

      def reset
        @start_time = nil
        Scheduler.current.cancel self
      end

      def active?
        @start_time
      end

      def idle?
        not active?
      end

      private 

      def do_wait
        Scheduler.current.wait_until @start_time + @time, self do
          @start_time = nil
          notify_finish
        end
      end
    end
  end
end




