include 'ruby_plc/sequences/step_base'

module RubyPlc
  module Sequences
    class InParallel
      include StepBase
      attr_reader :name

      def initialize(name = nil)
        @name = name
        @steps = []
        yield self if block_given?      
      end

      def step(s)
        if s.respond_to? :to_step
           @steps << s.to_step
        else
           @steps << s
        end
        @steps.last.on_exit do
          continue! if finished?
        end
      end

      def active?
        @steps.inject(false) {|act, step| act || step.active? }
      end

      def perform_start
        @steps.each {|s| s.start }
      end

      def perform_reset
        @steps.each {|s| s.reset }
      end
    end
  end
end


