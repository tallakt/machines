require 'machines/timedomain/analog'
require 'machines/timedomain/timer'
require 'machines/etc/notify'

module Machines
  module Timedomain
    class AnalogValue < Analog
      def initialize(value = nil)
        @name, @description = nil
        @v = value
      end

      def v=(val)
        if @v != val
          @v = val
          notify_change
        end
        @v
      end

      def v
        @v
      end
    end
  end
end







