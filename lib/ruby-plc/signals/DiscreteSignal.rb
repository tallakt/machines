module RubyPlc
  module Physical
    module DiscreteSignal
      attr_accessor :name, :description

      def initialize
        @re_listeners = []
        @fe_listeners = []
        @name, @description = nil
      end

      def ton(time)
        # TODO
      end

      def tof(time)
        # TODO
      end

      def &&(other)
        AndSignal.new(self, other)
      end

      def ||(other)
        OrSignal.new(self, other)
      end

      def on_re(&block)
        @re_listeners << block
      end

      def on_fe(&block)
        @fe_listeners << block
      end

      def on_change(&block)
        @fe_listeners << block
        @re_listeners << block
      end

      def data_change(value)
        @re_listeners.each {|l| l.call } if value
        @fe_listeners.each {|l| l.call } unless value
      end
    end
  end
end





