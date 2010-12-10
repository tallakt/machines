require 'machines/timedomain/discrete_base'

module Machines
  module Timedomain 
    class SR < DiscreteBase
      attr_reader :v

      def initialize(options = {})
        @set_has_priority = options[:set_has_priority]
        @value = !!options[:initial]
        s = DiscreteSink.new options[:set]
        s.on_change { recalc_notify }
        r = DiscreteSink.new options[:reset]
        r.on_change { recalc_notify }
        recalc
        yield self if block_given?
      end

      def v
        recalc_notify
        @value
      end

      def s=(signal)
        s.sink signal
      end


      def r=(signal)
        r.sink signal
      end


      private 
      
      def recalc
        if @set_has_priority
          (@value && !@r.v) || @s.v
        else
          (@value || @s.v) && !@r.v
        end
      end

      def recalc_notify
        @value = calc_and_nofify(@value) { recalc }
        end
      end
    end
  end
end


