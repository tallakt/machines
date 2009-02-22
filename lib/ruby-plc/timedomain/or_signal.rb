module RubyPlc
  module Physical
    class OrSignal < BinaryOpSignal
      def v
        a.v || b.v
      end
    end
  end
end


