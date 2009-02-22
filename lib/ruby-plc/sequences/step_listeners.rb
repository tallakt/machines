module RubyPlc
  module Sequences
    module StepListeners
      def init_step_listeners
        @enter_l = []
        @exit_l = []
        @reset_l = []
      end

      def on_exit(&block)
        @exit_l << block
      end

      def on_enter(&block)
        @enter_l << block
      end

      def on_reset(&block)
        @reset_l << block
      end

      def notify_enter
        call_listeners @enter_l
      end

      def notify_exit
        call_listeners @exit_l
      end

      def notify_reset
        call_listeners @reset_l
      end

      private

      def call_listeners(l)
        l.each do |callback|
          callback.call
        end
      end
    end
  end
end



