include 'ruby_plc/sequences/step_base'
include 'ruby-plc/sequences/sequence'

module RubyPlc
  module Sequences
    class StackSequence
      include StepBase
      attr_reader :name

      def initialize(name = nil, options = {})
        @name = name
        @up = Sequence.new nil, options
        @down = Sequence.new nil, :reverse => true
        @up.default_next_step = @down
        @down.at_end { continue! }
        yield self if block_given?      
      end

      def step(s)
        if s.respond_to? :up_step && s.respond_to? :down_step
          up_step s.up_step
          down_step s.down_step
        else 
          up_step to_step(s)
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

      def perform_start
        @up.start
      end

      def perform_reset
        @up.reset
        @down.reset
      end
    end
  end
end

