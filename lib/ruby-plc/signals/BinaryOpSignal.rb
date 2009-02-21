module RubyPlc
  module Physical
    class BinaryOpSignal < DiscreteSignal
      def initialize(a, b)
        a.on_change { update }
        b.on_change { update }
        @v = v
      end

      # Method v must be defined in concrete classes

      private

      def update
        old = @v
        @v = v
        data_change @v unless old == @v
      end
    end
  end
end


