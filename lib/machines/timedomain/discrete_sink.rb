require 'machines/timedomain/discrete_base'

module Machines
  module Timedomain
    # The DiscreteSink allocates a slot where a signal will be assigned at a later
    # time. The signal may only be assigned once
    #
    # Code example:
    #
    #   s = DiscreteSink.new
    #   s.on_re { puts 'rising edge' }
    #   d = Discrete.new
    #   d.v = 1
    #   s.sink d.ton(10)
    #
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
        raise RuntimeError.new 'DiscreteSink may only be assigned to a source once' unless @source.nil?
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
