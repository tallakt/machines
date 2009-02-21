module RubyPlc
  module Sequences
    class WaitStep < Step
      def initialize(timeout, name = nil)
        super name
        @timeout = timeout
        continue_when { duration > @timeout }
        end
      end
    end
  end
end



