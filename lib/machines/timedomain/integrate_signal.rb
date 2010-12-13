require 'machines/timedomain/sampler'

module Machines
  module Timedomain
    class AnalogBase
    end

    class IntegrateSignal < AnalogBase
      attr :v

      def initialize(input, options = {})
        @in = AnalogBase.to_analog input
        @v = options[:initial] || 0.0
        dt = options[:dt] || 1.0
        @prev_t = @prev_in = nil

        @enable = DiscreteSink.new options[:enable]
        @enable.on_re { calc }
        @enable.on_fe do
          calc
          @prev_t = @prev_in = nil
        end

        sampler = options[:sampler] || Sampler.new(dt)
        sampler.on_sample { calc }
      end

      def enable=(enable_signal)
        @enable.sink enable_signal
      end


      private

      def calc
        t = Time.now
        if @prev_in && @prev_t
          @v += (Time.now - @prev_time) * 0.5 * (@in.v + @prev_in) 
        end
        @prev_t = t
        @prev_in = @in.v
      end
    end
  end
end
