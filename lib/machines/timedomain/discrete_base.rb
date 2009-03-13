require 'machines/timedomain/timer'
require 'machines/timedomain/binary_op_discrete'
require 'machines/timedomain/negated_discrete'
require 'machines/etc/notify'

module Machines
  module TimeDomain
    class DiscreteBase
      extend Notify

      attr_accessor :name, :description
      notify :re, :fe, :change

      def initialize
        @name, @description = nil
      end

      def ton(time)
        timer = Timer.new time
        on_re { timer.start }
        if block_given?
          on_fe { timer.reset }
          timer.at_end { yield }
          self
        else
          result = Discrete.new
          on_fe do
            timer.reset
            result.v = false
          end
          timer.at_end { result.v = true }
          result
        end
      end

      def tof(time)
        timer = Timer.new time
        on_fe { timer.start }
        if block_given? 
          on_re { timer.reset }
          timer.at_end { yield }
          self
        else
          result = Discrete.new
          on_re do
            timer.reset 
            result.v = true 
          end
          timer.at_end { result.v = false }
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

      alias :not :invert

      private 

      def to_discrete(disc)
        if disc.respond_to? :v
          disc.v
        else
          disc
        end
      end
    end
  end
end





