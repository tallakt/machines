include 'ruby-plc/timedomain/timer'
include 'ruby-plc/etc/notify'

module RubyPlc
  module Physical
    module Analog
      extend Notify

      attr_accessor :name, :description
      notify :change

      def initialize(value = nil)
        @name, @description = nil
        @v = value

        %w(+ - * \ ** % <=>).each do |op|
          module_eval <<-EOF
            def #{op}(other)
              Analog.combine(self, other) do |a, b|
                a #{op} b
              end
            end
          EOF
        end

        %(== != < > >= <= ===).each do |op|
          module_eval <<-EOF
            def #{op}(other)
              Analog.combine_to_discrete(self, other) do |a, b|
                a #{op} b
              end
            end
           EOF
        end
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
        result = Analog.new combine_helper_call block, signals
        signals.each do |sig|
          if sig.respond_to? :on_change
            sig.on_change do
              result.v = combine_helper_call block, signals
            end
          end
        end
        result
      end

      def Analog.combine_to_discrete(*signals, &block)
        result = ValSignal.new combine_helper_call block, signals
        signals.each do |sig|
          if sig.respond_to? :on_change
            sig.on_change do
              result.v = combine_helper_call block, signals
            end
          end
        end
        result
      end

      private

      def Analog.combine_helper_call(block, *signals)
        # TODO could be made more efficient by introducing a singleton method to result eg block.call(signals[0], signals[1].v)
        block.call(signals.map {|s| if s.respond_to?(:v) s.v else s end })
      end

    end
  end
end






