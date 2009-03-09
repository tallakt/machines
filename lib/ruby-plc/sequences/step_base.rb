require 'ruby-plc/etc/notify.rb'

module RubyPlc
  module Sequences
    module StepBase
      extend Notify

      notify :enter, :exit, :reset
      attr_accessor :default_next_step, :otherwise_step
      attr_reader :start_time, :prev_duration
      
      def on_exit_reset(&proc)
        on_exit { yield }
        on_reset { yield }
      end

      # Active signal - dont add listeners unless necessary
      def active_signal
        @active_signal ||= ValSignal.new
      end

      alias :original_notify_enter, :notify_enter
      def notify_enter
        original_notify_enter
        @active_signal.v = true if @active_signal
      end


      alias :original_notify_exit, :notify_exit
      def notify_exit
        original_notify_exit
        @active_signal.v = false if @active_signal
      end

      def finished?
        not active? # active? method should be present in including class
      end
      
      def start
        if may_start? # may_start? defined in including class
          @start_time = Sequencer.now
          perform_start  # startup must be defined in including class
          notify_enter

          # check if going directly to exit
          step = nil
          if @exit_conditions
            tb = @exit_conditions.find {|x| condition_true? x.first }
            if tb
              step = tb.last || default_next_step
            else
              step = otherwise_step
            end
          else
            step = otherwise_step || default_next_step
          end

          private_continue step if step
        end
      end

      def continue
        private_continue otherwise_step || default_next_step
      end

      def continue_if(condition, step = nil)
        condition.on_re { private_continue step } if condition.respond_to? :on_re
        @exit_conditions ||= []
        @exit_conditions << [condition, step]
      end

      def continue_to(step)
        @next_step = step
      end

      def otherwise_to(step)
        @otherwise_step = step
      end

      def continue_from(step)
        step.contine_to self
      end

      def otherwise_from(step)
        step.otherwise_to self
      end

      def continue_from_if(condition, step)
        step.continue_if condition, self
      end

      def duration
        @start_time && (Sequencer.now - @start_time)
      end

      def reset
        perform_reset # defined in class 
        notify_reset
      end

      # Framework method
      def perform_start
        @active = true
      end

      # Framework method
      def may_continue?
        true
      end

      # Framework method
      def perform_finish
        @active = false
      end
      
      # Framework method
      def may_start?
        finished?
      end

      private 

      def private_continue(step)
        if may_continue? 
          Sequencer::at_once do 
            @prev_duration = duration
            notify_exit
            perform_finish
            step.start 
          end
        end
      end

      def condition_true?(cond)
        case cond
        when Proc
          cond.call
        when DiscreteSignal
          cond.v
        else
          cond
        end
      end

      def to_step(s)
        if s.respond_to? :to_step
          s.to_step
        else
          s
        end
      end

   end
  end
end



