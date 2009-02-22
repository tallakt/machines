include 'ruby-plc/timedomain/sequencer'

module RubyPlc
  module TimeDomain
    class Timer
      def initialize(time)
        @time = time
        @start_time = nil
        @listeners = []
      end

      def time=(t)
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

      def at_end(&block)
        @listeners << block
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

      def wait_done
        @start_time = nil
        @listeners.each {|l| l.call }
      end

      def do_wait
        Sequencer::wait_until @start_time + @time, self do
          wait_done
        end
      end
    end
  end
end




