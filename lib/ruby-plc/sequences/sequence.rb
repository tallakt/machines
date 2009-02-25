include 'ruby-plc/sequences/step_listeners'
include 'ruby-plc/timedomain/wait_step'
include 'ruby-plc/timedomain/timer'
include 'ruby-plc/timedomain/sequencer'

mmodule RubyPlc
  module Sequences
    class Sequence
      include StepListeners

      attr_reader :name

      def initialize(name = nil, options = {})
        init_step_listeners
        @name = name
        @steps = []
        @current_step_index = nil # index of current step
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
        Timer t = Timer.new delay
        on_exit do
          t.start
          t.at_end do 
            start
          end
        end
      end


      def finished?
        current_step
      end

      def active?
        not finished
      end
      
      def start
        if not current_step || @steps.any?
          notify_enter
          @current_step_index = 0 
        end
      end

      def current_step
        @current_step_index && @steps[@current_step_index]
      end

      def reset(mode = :all)
        @steps.each {|s| s.reset(mode) } if mode == :all
        @steps[0..@current_step_index].each {|s| s.reset(mode) } if (mode == :used && @current_step_index)
        @current_step_index = nil
        notify_reset
      end

      private

      def add_step(s)
        if @options[:reverse]
          @steps.unshift s
        else
          @steps << s
        end

        step.on_exit do
          Sequencer::at_once do
            current_step_finished
          end
        end
      end

      def current_step_finished
        if @current_step_index
          @current_step_index += 1
          if @current_step_index >= @steps.size
            @current_step_index = nil 
            notify_exit
          end
          current_step.start if current_step
        end
      end
    end
  end
end
