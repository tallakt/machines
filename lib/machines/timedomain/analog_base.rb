require 'machines/etc/notify'
require 'machines/timedomain/discrete'
require 'machines/timedomain/integrate_signal'
require 'machines/timedomain/derivate_signal'
require 'machines/timedomain/analog'

module Machines
  module Timedomain
    class AnalogBase
    end

    class Analog < AnalogBase
    end

    class AnalogBase
      extend Notify
      attr_accessor :name, :description
      notify :change

      def initialize
        @name, @description = nil
      end

      # inherited classes should have the :v accessor

      def AnalogBase.combine(*signals)
        analog_signals = signals.map {|s| Analog.to_analog s }
        result = Analog.new(yield analog_signals.map {|s| s && s.v })
        analog_signals.each do |sig|
          sig.on_change do
            result.v = yield analog_signals.map {|s| s && s.v }
          end
        end
        result
      end

      def AnalogBase.combine_to_discrete(*signals, &block)
        analog_signals = signals.map {|s| Analog.to_analog s }
        result = Discrete.new yield(analog_signals.map {|s| s && s.v })

        signals.each do |sig|
          sig.on_change do
            result.v = yield analog_signals.map {|s| s && s.v }
          end
        end
        result
      end

      def AnalogBase.selection(sel, when_true, when_false)
        ss = DiscreteBase.to_discrete sel
        wt = AnalogBase.to_analog when_true
        wf = AnalogBase.to_analog when_false
        res = Analog.new(ss.v ? wt.v : wf.v)
        [ss, wt, wf].each do |sig|
          sig.on_change { res.v = (ss.v ? wt.v : wf.v) }
        end
        res
      end

      def AnalogBase.to_analog(v)
        case v
        when AnalogBase
          v
        when DiscreteBase
          vv = Analog.new v.v ? 1.0 : 0.0
          v.on_re { vv.v = 1.0 }
          v.on_fe { vv.v = 0.0 }
          vv
        when nil
          v
        else
          Analog.new v
        end
      end

      def integrate(options = {})
        IntegrateSignal.new self, options
      end

      def derivate(options = {})
        DerivateSignal.new self, options
      end

      def sample(options = {}) 
        if options[:sampler]
          smp = options[:sampler]
        else
          dt = options[:dt] || 1.0
          smp = Sampler.new dt
        end
        result = Analog.new v
        smp.on_sample { result.v = v }
        result
      end

      def to_disc
        Discrete.new.tap do |d|
          if block_given?
            d.v = yield v
            on_change do
              d.v = yield v
            end
          else
            d.v = v
            on_change do
              d.v = v
            end
          end
        end
      end

      # add operators returing a new Analog
      %w(+ - * \ ** % <=>).each do |op|
        AnalogBase.module_eval <<-EOF
          def #{op}(other)
            AnalogBase.combine(self, other) do |a, b|
              a #{op} b
            end
          end
        EOF
      end

      # add operators returning a new Discrete signal
      %w(== < > >= <= ===).each do |op| # != not supported
        AnalogBase.module_eval <<-EOF
          def #{op}(other)
            AnalogBase.combine_to_discrete(self, other) do |a, b|
              a #{op} b
            end
          end
         EOF
      end

      private

      # This is a helper method for classes deriving from AnalogBase
      # when changing their value :v. It will perform a calculation
      # in a block and return the new value. If the value has changed
      # it will also notify
      def calc_and_notify(old_value)
        new_val = yield
        notify_change if (new_val != old_value)
        new_val
      end
    end
  end
end






