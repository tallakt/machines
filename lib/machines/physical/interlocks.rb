module Machines
  module Physical
    class Interlock
      def initialize
        @conditions = {}
        yield self if block_given?
      end

      def add(condition, description = nil) 
        @conditions[condition] = description || condition.name || ''
      end


      def unlocked?
        @conditions.keys.inject {|result, cond| result & cond } 
      end

      def interlocked?
        unlocked?.not
      end

      def why
        @conditions.keys.find {|c| c.v }.map {|c| @conditions[c] }
      end
    end
  end
end





