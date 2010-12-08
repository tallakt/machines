require 'machines/etc/notify'
require 'machines/timedomain/discrete'


module Machines
  module Timedomain
    class Analog
      extend Notify
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

      def Analog.combine(*signals, &block)
        calc_proc = signals_value_calc_proc(*signals, &block)
        result = Analog.new calc_proc.call
        signals.each do |sig|
          if sig.respond_to? :on_change
            sig.on_change do
              result.v = calc_proc.call
            end
          end
        end
        result
      end

      def Analog.combine_to_discrete(*signals, &block)
        calc_proc = signals_value_calc_proc(*signals, &block)
        result = Discrete.new calc_proc.call

        signals.each do |sig|
          if sig.respond_to? :on_change
            sig.on_change do
              result.v = calc_proc.call
            end
          end
        end
        result
      end

      def Analog.to_analog(v)
        case v
        when Analog
          v
        when nil
          v
        else
          Analog.new v
        end
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
        Analog.module_eval <<-EOF
          def #{op}(other)
            Analog.combine(self, other) do |a, b|
              a #{op} b
            end
          end
        EOF
      end

      # add operators returning a new Discrete signal
      %w(== < > >= <= ===).each do |op| # != not supported
        Analog.module_eval <<-EOF
          def #{op}(other)
            Analog.combine_to_discrete(self, other) do |a, b|
              a #{op} b
            end
          end
         EOF
      end

      private

      # create a proc that will cal the block with the given signals
      # as inputs. The inputs are used either as values or as the 
      # values of signals. Ie. if the signal supports the :v method
      # or variable, signal.v is used, otherwise, signal itself is 
      # used
      def Analog.signals_value_calc_proc(*signals, &block)
        value_signals = []
        signals.each_with_index do |sig, ii|
          sig_val = "signals[#{ii}]" 
          if sig.respond_to? :v then 
            sig_val += '.v'
          end
          value_signals << sig_val
        end
        eval <<-EOF
          Proc.new { block.call(#{value_signals.join ','}) }  
        EOF
      end
    end
  end
end






