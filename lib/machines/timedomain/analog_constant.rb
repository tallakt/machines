include 'machines/timedomain/analog'

module Machines
  module Physical
    class AnalogConstant < AnalogBase
      attr_reader :v

      def initialize
        @name, @description = nil
        @v = value
      end

      def on_change
        # no need
      end
    end
  end
end







