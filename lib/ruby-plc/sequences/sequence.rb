include 'ruby-plc/sequences/step_base'
include 'ruby-plc/timedomain/wait_step'
include 'ruby-plc/timedomain/timer'
include 'ruby-plc/timedomain/sequencer'

mmodule RubyPlc
  module Sequences
    class Sequence
      include StepBase

      attr_reader :name

      def initialize(name = nil, options = {})
        @name = name
        @steps = []
        @options = options
        yield self if block_given?      
        if @options[:auto_start]
          Sequencer::at_once { start }
        end
        if @options[:cyclic]
          on_exit do 
            Sequencer::at_once { start }
          end
        end

      end

      def step(s)
        if s.respond_to? :to_step
          add_step s.to_step
        else
          add_step s
        end
        s
      end

      def wait(time)
        step WaitStep.new time
      end

      def circular(delay = 100)
        on_exit { Sequencer::wait(delay, self) { start } }
      end

      def active?
        steps.inject(false) {|act, step| act || step.active? }
      end
      
      def may_continue?
        finished?
      end

      def perform_start
        @steps.first && @steps.first.start
      end

      def current_step
        @steps.find {|s| s.active? }
      end

      def perform_reset
        @steps.each {|s| s.reset }
      end

      private

      def add_step(s)
        if @options[:reverse]
          s.default_next_step = @steps.first
          @steps.unshift s
        else
          @steps.last.default_next_step = s
          @steps << s
        end
        s.on_exit { continue! if s == @steps.last }
      end
    end
  end
end
