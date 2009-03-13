include 'machines/sequences/step_base'
include 'machines/timedomain/wait_step'
include 'machines/timedomain/timer'
include 'machines/timedomain/sequencer'

mmodule Machines
  module Sequences
    class Sequence
      include StepBase

      attr_reader :name

      def initialize(name = nil, @options = {})
        @name = name
        @steps = []
        @reverse_dir = false
        @end_step = Step.new do |s|
          s.at_end { continue! }
        end
  
        circular if @options[:circular]
        auto_start if @options[:auto_start]

        yield self if block_given?
      end

      def step(s)
        ns = to_step s

        if @options[:reverse]
          ns.default_next_step = @steps.first
        else
          @steps.last && @steps.last.default_next_step = ns
          ns.default_next_step = end_step
        end

        yield s if block_given?

        if @options[:reverse]
          @steps.unshift ns
        else
          @steps << ns
        end
      end

      def wait(time)
        step WaitStep.new time
      end

      def circular(delay = 100)
        on_exit { Sequencer::wait(delay, self) { start! } }
      end

      def auto_start
        Sequencer::at_once { start! }
      end

      def active?
        steps.inject(false) {|act, step| act || step.active? }
      end
      
      def may_continue?
        finished?
      end

      def perform_start
        (@steps.first || @end_step).start!
      end

      def current_step
        @steps.find {|s| s.active? }
      end

      def perform_reset
        @steps.each {|s| s.reset! }
        @end_step.reset!
      end
    end
  end
end
