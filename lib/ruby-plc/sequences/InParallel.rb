module RubyPlc
  module Sequences
    class InParallel
      attr_reader :name

      def initialize(name = nil)
        @name = name
        @steps = []
        yield self if block_given?      
      end

      def step(s)
        if s.respond_to? :to_step
           @steps << s.to_step
        else
           @steps << s
        end
      end

      def run
        @steps.each {|s| s.run }
      end

      def finished?
        # All steps finished
        @steps.inject(true) {|result, step| result &&= step.finished? }
      end
      
      def active?
        not finished?
      end

      def start
        @steps.each {|s| s.start }
      end

      def reset
        @steps.each {|s| s.reset }
      end
    end
  end
end


