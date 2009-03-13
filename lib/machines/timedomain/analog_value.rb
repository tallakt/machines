include 'machines/timedomain/analog'
include 'machines/timedomain/timer'
include 'machines/etc/notify'

module Machines
  module Physical
    module AnalogValue < Analog
      extend Notify
      include Analog

      attr_accessor :name, :description
      notify :change

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







