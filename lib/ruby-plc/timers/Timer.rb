module RubyPlc
  module Timers
    class Timer
      attr_reader :time

      def initialize(time)
        @time = time
        @start_time = nil
        @listeners = []
      end

      def elapsed
        if @start_time
          Time::now - start
        else
          nil
        end
      end

      def start
        @start_time = Time::now
      end

      def at_end(&block)
        @listeners << block
      end

      def reset
        @start_time = nil
      end

      def active?
        @start_time
      end

      def idle?
        not active?
      end

      def run
        if elapsed >= @time
          @start_time = nil
          @listeners.each {|l| l.call }
        end
      end
    end
  end
end




