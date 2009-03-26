include 'machines/etc/notify'
include 'machines/timedomain/sequencer'

module Machines
  module Timedomain

    # The Sample class will notify all listeners to the #on_sample function 
    # at even intervals
    class Sampler
      extend Notify

      notify :sample

      def initialize(sample_time, time_shift = 0)
        @sample_time, @time_shift = sample_time, time_shift
        @running = false
        if @sample_time.respond_to? :on_change
          @sample_time.on_change do
            if @sample_time == time # in case new time has been assigned
              Sequencer::cancel self
              @timer.reset!
              wait_for_next_sample
            end
          end
        end
      end

      def running?
        @running
      end

      def start
        @running = true
        wait_for_next_sample
      end

      def stop
        Sequencer::cancel self
        @running = false
      end

      def sample_time
        @sample_time
      end

      def sample_time=(t)
        @sample_time = t
        if t.respond_to? :on_change
          t.on_change do
            if @sample_time == t
              Sequencer::cancel self
              wait_for_next_sample
            end
          end
        end
      end

      def time_shift
        @time_shift
      end

      def time_shift=(t)
        @time_shift = t
        if t.respond_to? :on_change
          t.on_change do
            if @time_shift == t
              Sequencer::cancel self
              wait_for_next_sample
            end
          end
        end
      end


      private 

      def wait_for_next_sample
        Sequencer::wait @sample_time - ((Sequencer::now - @time_shift) % @sample_time), self do
          nofity_sample
        end
      end
    end
  end
end





