include 'ruby_plc/sequences/step_base'

module RubyPlc
  module Sequences
    class InParallel
      include StepBase
      attr_reader :name

      def initialize(name = nil)
        @name = name
        @steps = []
        @end_step = Step.new
        @steps << @end_step
        yield self if block_given?      
      end

      def step(s)
        steps << to_step s
        @steps.last.on_exit { continue! }
          continue!
        end
      end

      def active?
        @steps.inject(false) {|act, step| act || step.active? }
      end

      def may_continue?
        finished?
      end

      def perform_start
        @steps.each {|s| s.start! }
      end

      def perform_reset
        @steps.each {|s| s.reset! }
      end
    end
  end
end


