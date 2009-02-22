include 'ruby_plc/sequences/step_listeners'

module RubyPlc
  module Sequences
    class InParallel
      include StepListeners
      attr_reader :name

      def initialize(name = nil)
        init_step_listeners
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
        step = @steps.last
        step.on_exit do
          notify_exit if finished?
        end
      end

      def finished?
        # All steps finished
        @steps.inject(true) {|result, step| result &&= step.finished? }
      end
      
      def active?
        not finished?
      end

      def start
        notify_enter
        @steps.each {|s| s.start }
      end

      def reset(mode = :all)
        @steps.each {|s| s.reset(mode) }
        notify_reset
      end
    end
  end
end


