include 'ruby_plc/sequences/step_listeners'

mmodule RubyPlc
  module Sequences
    class Branch
      include StepListeners

      attr_reader :name

      def initialize(name = nil)
        init_step_listeners
        @name = name
        @branches = []
        @started = false
        @chosen_branch = nil
        yield self if block_given?      
      end

      def branch(s, condition_signal)
        if s.respond_to? :to_step
           @branches << [condition_signal, s.to_step]
        else
           @branches << [condition_signal, s]
        end
        step = @branches.last.last
        condition_signal.at_re do
          start_branch step
        end
        s.at_end do
          finish_up
        end
      end

      def finished?
        not active?
      end
      
      def active?
        started
      end

      def start
        unless @started
          @started = true
          notify_enter
          choose_branch
        end
      end

      def reset(mode = :all)
        @branches.each {|br| br.last.reset(mode) } if mode == :all
        notify_reset
      end


      private

      def start_branch(branch)
        if branch && not @chosen_branch
          @chosen_branch = branch
          branch.start
        end
      end

      def choose_branch
        start_branch(@branches.find {|br| br.first.call })
      end

      def finish_up
        notify_exit
        @started = false
        @chosen_branch = nil
      end
    end
  end
end



