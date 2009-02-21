module RubyPlc
  module Sequences
    class Branch
      attr_reader :name

      def initialize(name = nil)
        @name = name
        @branches = []
        @started = false
        @chosen_branch = nil
        yield self if block_given?      
      end

      def branch(s, &condition)
        if s.respond_to? :to_step
           @branches << [condition, s.to_step]
        else
           @branches << [condition, s]
        end
      end

      def run
        if active?
          if @chosen_branch 
            @chosen_branch.run
            if @chosen_branch.finished?
              started = false
              @chosen_branch = nil
            end
          else
            choose_branch
          end
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
          choose_branch
        end
      end

      def reset(mode = :all)
        @branches.each {|br| br.last.reset(mode) }
      end


      private

      def choose_branch
        unless @chosen_branch
          @branches.each do |br|
            condition, step = br
            if condition.call
              @chosen_branch = br 
              br.start
              break
            end            
          end
        end
      end

    end
  end
end



