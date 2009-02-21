module RubyPlc
  module Physical
    class ValSignal < DiscreteSignal
      def initialize
        super 
        @v = false
        yield self if block_given?
      end

      def v
        @v
      end

      def v=(new_val)
        old_v = @v
        if new_val
          @v = true
          data_change v unless old_v
        else
          @v = false
          data_change v if old_v
        end
      end
    end
  end
end
