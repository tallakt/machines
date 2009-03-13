module Machines
  module Sequences
    class WaitStep < Step
      attr_accessor :timeout

      def initialize(timeout, name = nil)
        super name
        @timeout = timeout
        t = Timer.new(timeout) { continue! }
        on_reset { t.reset }
      end
    end
  end
end



