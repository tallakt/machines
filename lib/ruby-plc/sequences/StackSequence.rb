module RubyPlc
  module Sequences
    class StackSequence
      attr_reader :name

      def initialize(name = nil, options = {})
        @name = name
        @up = Sequence.new nil, options
        @down = Sequence.new nil, :reverse => true
        yield self if block_given?      
      end

      def step(s)
        if s.respond_to? :up_step && s.respond_to? :down_step
          @up.step s.up_step
          @down.step s.down_step
        else 
          @up.step s
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

      def run
        if @up.active?
          @up.run
          if @up.finished?
            @down.start
          end
        else
          @down.run if @down.active?
        end
      end

      def finished?
        @up.finished? && @down.finished?
      end

      def start
        @up.start
      end

      def reset
        @up.reset
        @down.reset
      end
    end
  end
end

