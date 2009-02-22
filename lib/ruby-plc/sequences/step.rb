include 'ruby-plc/sequences/step_listeners'
include 'ruby-plc/timedomain/sequencer'

module RubyPlc
  module Sequences
    class Step
      include StepListeners

      attr_reader :name, :start_time, :prev_duration

      def initialize(name = nil)
        @name = name
        @active = false
        @start_time = nil
        @prev_duration = nil
        yield self if block_given?
      end

      def start
        if finished?
          @active = true
          @start_time = Sequencer.now
          notify_enter
        end
      end

      def continue
        if active?
          @active = false
          calc_end_duration
          notify_exit
        end
      end
      
      def continue_when(signal)
        signal.on_re do
          continue
        end
      end

      def reset(mode = nil)
        active = false
        calc_end_duration
        nitify_reset
      end

      def active?
        active
      end

      def finshed?
        not active?
      end

      def duration
        @start_time && (Sequencer.now - @start_time)
      end

      private

      def calc_end_duration
        @prev_duration = duration
        @start_time = nil
      end
    end
  end
end


