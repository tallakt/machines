module RubyPlc
  module Physical
    class Interlock
      def initialize
        @conditions = {}
        yield self if block_given?
      end

      def add(description, &condition) 
        @conditions[condition] = description
      end


      def unlocked?
        # all conditions must be true
        @conditions.keys.inject(true) {|result, cond| result && cond.call } 
      end

      def interlocked?
        not unlocked?
      end

      def why
        @conditions.keys.find {|cond| cond.call? }.map {|cond| @conditions[cond] }
      end
    end
  end
end





