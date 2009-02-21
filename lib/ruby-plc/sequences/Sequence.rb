module RubyPlc
  module Sequences
    class Sequence
      attr_reader :name

      def initialize(name = nil, options = {})
        @name = name
        @steps = []
        @current_step_index = nil # index of current step
        @options = options
        yield self if block_given?      
      end

      def step(s)
        if s.respond_to? :to_step
          add_step s.to_step
        else
          add_step s
        end
      end

      def wait(time)
        step WaitStep.new time
      end

      def run
        if active?
          current_step.run
          if current_step.finished?
            @current_step_index += 1
            @current_step = nil if @current_step >= @steps.size
            if current_step
              current_step.start
            end
          end
        else
          if @options[:auto_start]
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
        @current_step_index = 0 unless (current_step or @steps.empty?)
      end

      def current_step
        @current_step && @steps[@current_step]
      end

      def reset(mode = :all)
        @steps.each {|s| s.reset(mode) } if mode == :all
        @steps[0..@current_step_index].each {|s| s.reset(mode) } if (mode == :used && @current_step_index)
        @current_step_index = nil
      end

      private

      def add_step(s)
        if @options[:reverse]
          @steps.unshift s
        else
          @steps << s
        end
      end

    end
  end
end
