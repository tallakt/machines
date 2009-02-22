include 'ruby-plc/timedomain/binary_op_signal'

module RubyPlc
  module Physical
    class AndSignal < BinaryOpSignal
      def v
        a.v && b.v
      end
    end
  end
end

