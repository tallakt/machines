module RubyPlc
  module Physical
    class Valve
      attr_reader :name, :description, :interlocks

      def initialize(name = nil, description = nil, options = {})
        @name, @description, @options = name, description, options
        @interlocks = Interlocks.new
        @manual = false
        yield self if block_given?
      end

      def open(mode = :auto)
        update_manual mode
        # TODO
      end

      def close(mode = :auto)
        update_manual mode
        # TODO
      end

      def open?
        # TODO
      end

      def closed?
        # TODO
      end

      def interlocked?
        interlocks.interlocked?
      end

      def manually_operated?
        manual
      end

      def normally_open
        @options[:normally_open] = true
      end
      # for use in a Stacksequence
      def up_step
        open_step
      end

      # for use in a Stacksequence
      def down_step
        close_step
      end

      def open_step
        Step.new do |s|
          s.on_enter { open }
          s.continue_when { open? }
          s.on_reset { close unless @options[:normally_open] }
        end
      end

      def close_step
        Step.new do |s|
          s.on_enter { close }
          s.continue_when { closed? }
          s.on_reset { open if @options[:normally_open] }
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




