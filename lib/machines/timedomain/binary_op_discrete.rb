require 'machines/timedomain/discrete_base'

module Machines
  module Timedomain 
    class DiscreteBase #:nodoc:
      # forward Declaration
    end

    class BinaryOpDiscrete < DiscreteBase
      def initialize(a, b, &op)
        a.on_change { recalc_nofify }
        b.on_change { recalc_nofify }
        @a, @b, @op = a, b, op
        @v = recalc
      end

      def v
        recalc
      end

      private


      def recalc
        @op.call to_discrete(@a), to_discrete(@b)
      end

      def recalc_nofity
        @v = calc_and_notify(@v) { recalc }
      end
    end
  end
end


