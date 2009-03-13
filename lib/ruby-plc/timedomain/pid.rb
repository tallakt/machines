require 'ruby-plc/timedomain/sampler.rb'
require 'ruby-plc/timedomain/analog_attr.rb'

module RubyPlc
  module Physical
    class PID
      analog_attr :p, :i, :d, :sample_time, :out_max, :out_min, :setpoint, :input
      attr_reader :output, :integral

      def initialize
        p = 1.0
        i = nil
        d = nil
        @previous = nil
        sample_time = 1.seconds
        yield self
        @sampler = Sampler.new @sample_time 
        @sampler.on_sample { calculate }
        calculate
      end

      def start
        unless running?
          @previous = nil
          @sampler.start
        end
      end

      def stop
        if running?
          @sampler.stop
        end
      end

      def running? 
        @sampler.running?
      end

      private 

      def calculate
        result = 0.0        
        error = @input.v - @setpoint.v
        old_integral = @integral

        if @d && (@d.v > 0.0) && @previous
          deriv = (@input.v - @previous) / @sample_time
          rd = deriv * @d.v
        else
          rd = 0.0
        end

        if @i && (@i.v > 0.0) 
          integral += error * @sample_time
          ri = 0.0
        else
          ri = 0.0
        end

        result = rd + ri + @p.v * erro


        @previous = @input.v
        @output ||= Analog.new result
        @output.v = result
      end
    end
  end
