module RubyPlc
  module Physical
    class AndSignal < BinaryOpSignal
      def v
        a.v && b.v
      end
    end
  end
end

