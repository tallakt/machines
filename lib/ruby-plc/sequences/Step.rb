module RubyPlc
  module Sequences
    class Step
      attr_reader :name, :start_time, :prev_duration

      def initialize(name = nil)
        @name = name
        @on_enter_proc, @on_exit_proc, @on_run_proc, @continue_when_proc, @on_reset_proc = nil
        @active = false
        @start_time = nil
        @prev_duration = nil
        yield self if block_given?
      end

      def on_exit(&block)
        @on_exit_proc = &block
      end

      def on_enter(&block)
        @on_enter_proc = &block
      end

      def on_run(&block)
        @on_run_proc = &block
      end

      def on_reset(&block)
        @on_reset_block = &block
      end

      def continue_when(&block)
        @continue_when_proc = &block
      end

      def start
        @active = true
        @start_time = Time.now
        call_if @on_enter_proc
      end

      def run
        if active?
          call_if @on_run_proc
          if should_continue?
            call_if @on_exit_proc
            @active = false
            end_duration
          end
        end
      end

      def reset(mode = nil)
        active = false
        end_duration
        call_if @on_reset_proc
      end

      def active?
        active
      end

      def finshed?
        not active?
      end

      def duration
        @start_time && (Time.now - @start_time)
      end

      private

      def call_if(proc)
        proc && proc.call
      end

      def end_duration
        @prev_duration = Time.now - @start_time
        @start_time = nil
      end

      def should_continue?
        if @continue_when_proc)
          @continue_when_proc.call
        else
          true
        end
      end
    end
  end
end


