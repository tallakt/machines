require 'machines/timedomain/discrete_base'

module Machines
  module Timedomain
    class Discrete < DiscreteBase
      def initialize(vv = false)
        @v = vv
        yield self if block_given?
      end

      def v
        @v
      end

      def v=(new_val)
        @v = calc_and_notify(@v) { new_val }
      end

      def set!
        v = true
      end

      def reset!
        v = false
      end
    end
  end
end
