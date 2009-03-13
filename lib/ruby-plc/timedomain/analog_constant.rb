include 'ruby-plc/timedomain/analog'

module RubyPlc
  module Physical
    class AnalogConstant < Analog
      attr_reader :v

      def initialize()
        @name, @description = nil
        @v = value
      end

      def on_change
        # no need
      end
    end
  end
end







