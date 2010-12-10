require 'machines/etc/notify'
require 'machines/timedomain/analog_base'

module Machines
  module Timedomain
    class Analog < AnalogBase
      def initialize(value = nil)
        @name, @description = nil
        @v = value
      end

      def v=(val)
        @v = calc_and_notify(@v) { val }
      end

      def v
        @v
      end
    end
  end
end






