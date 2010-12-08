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
        old_v = @v
        @v = !!new_val # ensure bool
        data_change @v if (old_v ^ @v)
      end

      private

      def data_change(value)
        notify_re if value
        notify_fe unless value
        notify_change
      end
    end
  end
end
