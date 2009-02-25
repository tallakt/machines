include 'ruby-plc/timedomain/sequencer'
include 'ruby-plc/etc/notify'

module RubyPlc
  module TimeDomain
    class Timer
      extend Notify

      notify :finish

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
          Sequencer::cancel self
          do_wait
        end
      end

      def time
        @time
      end

      def elapsed
        if @start_time
          Sequencer::now - start
        else
          nil
        end
      end

      def start
        @start_time = Sequencer::now
        do_wait
      end

      def reset
        @start_time = nil
        Sequencer
      end

      def active?
        @start_time
      end

      def idle?
        not active?
      end

      private 

      def do_wait
        Sequencer::wait_until @start_time + @time, self do
          @start_time = nil
          notify_finished
        end
      end
    end
  end
end




