require 'ruby-plc/timedomain/timer'
require 'ruby-plc/etc/notify'

module RubyPlc
  module TimeDomain
    class Analog
      extend Notify
      attr_accessor :name, :description
      notify :change

      def initialize(value = nil)
        @name, @description = nil
        @v = value

        %w(+ - * \ ** % <=>).each do |op|
          Analog.module_eval <<-EOF
            def #{op}(other)
              Analog.combine(self, other) do |a, b|
                a #{op} b
              end
            end
          EOF
        end

        %w(== < > >= <= ===).each do |op| # != not supported
          Analog.module_eval <<-EOF
            def #{op}(other)
              Analog.combine_to_discrete(self, other) do |a, b|
                a #{op} b
              end
            end
           EOF
        end
      end

      def Analog.combine(*signals, &block)
        result = Analog.new combine_helper_call(*signals, &block)
        signals.each do |sig|
          if sig.respond_to? :on_change
            sig.on_change do
              result.v = combine_helper_call *signals, &block
            end
          end
        end
        result
      end

      def Analog.combine_to_discrete(*signals, &block)
        result = Discrete.new combine_helper_call(*signals, &block)
        signals.each do |sig|
          if sig.respond_to? :on_change
            sig.on_change do
              result.v = combine_helper_call *signals, &block
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
          AnalogConstant.new v
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

      private

      def Analog.combine_helper_call(*signals, &block)
        # TODO could be made more efficient by introducing a singleton method 
        block.call(signals.map {|s| if s.respond_to?(:v) then s.v else s end })
      end

    end
  end
end






