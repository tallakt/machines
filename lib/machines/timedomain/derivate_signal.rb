module Machines
  module Timedomain
      class DerivateSignal < AnalogBase
      def initialize(input, options = {})
        @in = Analog.to_analog input
        @value = nil
        dt = options[:dt] || 1.0
        sampler = options[:sampler] || Sampler.new(dt)
        sampler.on_sample do 
          t = Time.now
          if @prev_in && @prev_t
            actual_dt = Time.now - @prev_t
            if actual_dt > 0.0
              v = (@in.v - @prev_in) / actual_dt
            else
              v = nil
            end
          end
          @prev_t = t
          @prev_in = @in.v
        end
      end
    end
  end
end
