require 'machines/timedomain/sampler.rb'
require 'machines/timedomain/analog_attr.rb'

module Machines
  module Physical
    class PID
      attr_reader :p, :i, :d, :sample_time, :output_range, :setpoint, :pv
      attr_reader :out, :integral, :derivative, :manual_output, :enable_signal, :error_signal

      def initialize(setpoint, pv, options = {})
        @kp = AnalogBase.to_analog(options[:kp]) || 1.0
        @ti = AnalogBase.to_analog(options[:ti])
        @td = AnalogBase.to_analog(options[:td])

        @pv = AnalogBase.to_analog pv
        @setpoint = AnalogBase.to_analog setpoint
        @output_range = options[:output_range]
        @manual_output = AnalogBase.to_analog options[:man] || 0.0

        if options[:sampler]
          @sampler = options[:sampler]
          @sample_time = @smapler.sample_time
          @enable_signal = @sampler.enable_signal && (options[:enable] || true)
        else
          @sample_time = AnalogBase.to_analog options[:sample_time] || 1.0
          @enable_signal = DiscreteBase.to_discrete(options[:en] || 1)
          @sampler = Sampler.new(@sample_time, :en => enable_signal)
        end

        @error_signal = @setpoint - @pv
        @integral =  (@setpoint - @pv).integrate :sampler => @sampler, :en => @enable_signal
        @derivative = @pv.derivative :sampler => @sampler

        # when changing Kp, adjust integral value to avoid jumps in output
        @kp_memory = @kp.v
        @kp.on_change do
          @integral.v *= @kp_memory / @kp.v
          @kp_memory = @kp.v
        end

        @continuous_output = AnalogBase.combine(@kp, @ti, @td, @error, @integral, @derivative) do |k, i, d, err, int, der|
          result = k * err
          if i
            result += k / i * int
          end
          if d
            result += k * d * der
          end

          # anti windup
          if @output_range
            range = @output_range.max - @output_range.min
            if result < @output_range.min - range * 0.01 
              @integral.v += (@output_range.min - result) * i / k
            end
            if result > @output_range.max + range * 0.01
              @integral.v -= (result - @output_range.max) * i / k
            end
            result = [[result, @output_range.max].min, @output_range.min].max
          end
        end

        # transfer from manual to auto without change in output
        bl = options[:bumpless].nil? ? true : options[:bumpless]
        if options[:bumpless]
          @enable_signal.on_re do
            diff = @auto_output.v - @manual_output.v
            @integral -= diff * @ti.v / @kp.v
          end
        end

        # Select output according to enabled input
        @output = AnalogBase.selection @enable, @auto_output, @manual_output

        # auto signal may change on any change in input, or only at the sample interval
        @output = @output.sample :sampler => @sampler unless options[:continuous]
      end
    end
  end
