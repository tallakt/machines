include 'ruby_plc/sequences/step_base'

module RubyPlc
  module Sequences
    class ChooseOne
      include StepBase

      attr_reader :name

      def initialize(name = nil)
        init_step_listeners
        @name = name
        @idle_step = Step.new
        @end_step = Step.new {|s| s.on_exit continue! }
        @steps = [@idle_step, @end_step]
        yield self if block_given?      
      end

      def branch(condition, step = nil)
        s = to_step(step) || Sequence.new
        @idle_step.continue_if condition, s
        s.default_next_step = @end_step
        @steps << s
        yield s if block_given?
      end

      def active?
        @steps.inject(false) {|act, s| act || s.active? }
      end

      def perform_start
        @idle_step.start!
      end

      def perform_reset
        @steps.each {|s| s.reset! }
      end
    end
  end
end



