include 'ruby_plc/sequences/step_listeners'
include 'ruby-plc/sequences/sequence'

module RubyPlc
  module Sequences
    class StackSequence
      include StepListeners

      attr_reader :name

      def initialize(name = nil, options = {})
        init_step_listeners
        @name = name
        @up = Sequence.new nil, options
        @down = Sequence.new nil, :reverse => true
        @up.at_end do
          @down.start
        end
        @down.at_end do
          notify_exit
        end
        yield self if block_given?      
      end

      def step(s)
        if s.respond_to? :up_step && s.respond_to? :down_step
          up_step s.up_step
          down_step s.down_step
        else 
          up_step s
        end
      end

      def up_step(s)
        @up.step s
      end

      def down_step(s)
        @down.step s
      end

      def up_wait(time)
        @up.wait time
      end

      def down_wait(time)
        @down.wait time
      end

      def finished?
        @up.finished? && @down.finished?
      end

      def start
        notify_enter
        @up.start
      end

      def reset(mode = :all)
        @up.reset(mode)
        @down.reset(mode)
        notify_reset
      end
    end
  end
end

