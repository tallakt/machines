require 'ruby-plc/timedomain/discrete_base'

module RubyPlc
  module TimeDomain
    class DiscreteSink < DiscreteBase
      attr_reader :source

      def initialize(source = nil)
        sink source
        yield self if block_given?
      end

      def v
        @source && to_discrete(@source)
      end

      def sink(source)
        throw RuntimeError.new 'DiscreteSink may only be assigned to a source once' unless @source.nil?
        @source = source
        if source.is_a? DiscreteBase
          source.on_change { notify_change }
          source.on_re { notify_re }
          source.on_fe { notify_fe }
        end
      end
    end
  end
end
