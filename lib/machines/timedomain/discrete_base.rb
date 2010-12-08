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
        memory = {}
        if block_given? 
          on_re do
            memory[:timer] = EventMachine::Timer time { yield }
          end
          on_fe do
            if memory[:timer] 
              memory_timer.cancel
            end
            memory[:timer] = nil
          end
          self
        else
          result = Discrete.new
          on_re do
            memory[:timer] = EventMachine::Timer time { result.v = true }
          end
          on_fe do
            if memory[:timer] 
              memory[:timer] .cancel
            end
            memory[:timer] = nil
            result.v = false
          end
          result
        end
      end

      def tof(time)
        memory = {}
        if block_given?
          on_fe do
            memory[:timer] = EventMachine::Timer time { yield }
          end
          on_re do
            if memory[:timer] 
              memory_timer.cancel
            end
            memory[:timer] = nil
          end
          self
        else
          result = Discrete.new
          on_fe do
            memory[:timer] = EventMachine::Timer time { result.v = false }
          end
          on_re do
            if memory[:timer] 
              memory_timer.cancel
            end
            memory[:timer] = nil
            result.v = true
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





