include 'ruby-plc/timedomain/timer'
include 'ruby-plc/timedomain/and_signal'
include 'ruby-plc/timedomain/or_signal'
include 'ruby-plc/etc/notify'

module RubyPlc
  module Physical
    module DiscreteSignal
      extend Notify

      attr_accessor :name, :description
      notify :re, :fe, :change

      def initialize
        @name, @description = nil
      end

      def ton(time)
        timer = Timer.new time
        on_re { timer.start }
        on_fe { timer.reset }
        timer.at_end { yield }
      end

      def tof(time)
        timer = Timer.new time
        on_fe { timer.start }
        on_re { timer.reset }
        timer.at_end { yield }
      end

      def &&(other)
        AndSignal.new(self, other)
      end

      def ||(other)
        OrSignal.new(self, other)
      end

      def data_change(value)
        notify_re if value
        notify_fe unless value
        notify_change
      end
    end
  end
end





