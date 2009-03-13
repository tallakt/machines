module Machines
  module Physical
    class Motor
      attr_reader :name, :description, :interlocks
      attr_accessor :start_out, :contactor

      def initialize(name = nil, description = nil)
        @name, @description = name, description
        @interlocks = Interlocks.new
        @manual = false
        @startup_timer = Timer.new 500
        yield self if block_given?
      end

      def startup_time
        @startup_timer.time
      end

      def startup_time=(t)
        @startup_timer.time = t
      end

      def start(mode = :auto)
        update_manual mode
        # TODO
      end

      def stop(mode = :auto)
        update_manual mode
        # TODO
      end

      def running?
        # TODO
      end

      def stopped?
        # TODO
      end

      def interlocked?
        interlocks.interlocked?
      end

      def manually_operated?
        manual
      end

      # for use in a Stacksequence
      def up_step
        start_step
      end

      # for use in a Stacksequence
      def down_step
        stop_step
      end

      def start_step
        Step.new do |s|
          s.on_enter { start }
          s.continue_when { running? }
          s.on_reset { stop }
        end
      end

      def stop_step
        Step.new do |s|
          s.on_enter { stop }
          s.continue_when { stopped? }
        end
      end

      private

      def update_manual(mode)
        case mode
        when :manual
          manual = true
        else
          manual = false
        end
      end
    end
  end
end



