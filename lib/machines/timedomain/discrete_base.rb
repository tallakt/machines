require 'machines/timedomain/timer'
require 'machines/timedomain/binary_op_discrete'
require 'machines/timedomain/negated_discrete'
require 'machines/etc/notify'
require 'eventmachine'

module Machines
  module Timedomain
    class DiscreteBase
      extend Notify

      attr_accessor :name, :description
      notify :re, :fe, :change

      def initialize
        @name, @description = nil
      end

      def ton(time)
        if block_given? 
          timer = Timer.new (time) { yield }
          on_re do
            timer.start
          end
          on_fe do
            timer.cancel
          end
          self
        else
          result = Discrete.new v
          timer = Timer.new(time) { result.set! }
          on_re do
            timer.start
          end
          on_fe do
            timer.cancel
            result.reset!
          end
          result
        end
      end

      def tof(time)
        if block_given?
          timer = Timer.new (time) { yield }
          on_fe do
            timer.start
          end
          on_re do
            timer.cancel
          end
          self
        else
          result = Discrete.new v
          timer = Timer.new(time) { result.reset! }
          on_fe do
            timer.start
          end
          on_re do
            timer.cancel
          end
          result
        end
      end

      def &(other)
        BinaryOpDiscrete.new(self, other) {|a, b| a && b }
      end

      def |(other)
        BinaryOpDiscrete.new(self, other) {|a, b| a || b }
      end

      def invert
        NegatedDiscrete.new(self)
      end

      # Helper method for classes based on DiscreteBase, never to be called directly
      # Every time a new value should be calculated, use this function to notify on
      # change and return the new value
      def calc_and_notify(old)
        vv = yield
        if (old && !vv) || (!old && vv)
          notify_change
          notify_re if vv
          notify_fe unless vv
        end
        !!vv # ensure bool
      end


      def DiscreteBase.to_discrete(value_or_signal)
        case value_or_signal
        when DiscreteBase
          value_or_signal
        when Analog
          raise RuntimeError.new 'Analog signal provided where discrete signal expected'
        when nil
          nil
        else
          Dicrete.new !!value_or_signal
        end
      end

      alias :not :invert
      alias :inv :invert
    end
  end
end





