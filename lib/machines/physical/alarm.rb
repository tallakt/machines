module Machines
  module Physical
    class Alarm
      attr_reader :alarm_time

      def initialize(condition, reason = nil)
        @condition = condition
        @reason = reason || condition.name || ''
        @in_alarm = Discrete.new @condition.v
        @condition.on_re do
          @in_alarm.set!
          @alarm_time = Time.now
        end
      end

      def active_signal
        condition
      end

      def in_alarm_signal
        @in_alarm
      end

      def ack
        if not @condition.v
          @in_alarm.reset!
          @alarm_time = nil
        end
      end

      def why
        @reason
      end
    end
  end
end

