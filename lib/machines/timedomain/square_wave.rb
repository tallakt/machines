require 'machines/timedomain/discrete'

module Machines
  module Timedomain
    class SquareWave < DiscreteBase
      def initialize(options = {})
        @dummy = Discrete.new
        t = options[:sample_time] || 1.0
        delay = options[:time_delay] || 0.0
        width = options[:width] || 0.5
        sampler = options[:sampler] || Sampler.new options[:sample_time] || 1.0
        sampler.on_sample do 
          @dummy.set!
          @dumy.reset!
        end
         
        @output = @dummy.tof(width)
        @output.on_re { notify_re }
        @output.on_fe { notify_fe }
        @output.on_change { notify_change }
      end

      def v
        @output.v
      end
    end
  end
end
