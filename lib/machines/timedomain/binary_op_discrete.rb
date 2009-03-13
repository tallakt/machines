require 'machines/timedomain/discrete_base'

module Machines
  module TimeDomain 
    class DiscreteBase #:nodoc:
      # forward Declaration
    end

    class BinaryOpDiscrete < DiscreteBase
      def initialize(a, b, &op)
        a.on_change { update }
        b.on_change { update }
        @a, @b, @op = a, b, op
        @v = v
      end

      def v
        @op.call to_discrete(@a), to_discrete(@b)
      end

      private


      def update
        old = @v
        @v = v
        data_change @v unless old == @v
      end

      def data_change(value)
        notify_re if value
        notify_fe unless value
        notify_change
      end
    end
  end
end


