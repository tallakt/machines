include 'machines/etc/notify'

module Machines
  module Timedomain
    # The DecimatedSampler class allows a sampler class to be divided into
    # a DecimatedSampler with a lower frequency. For example, if a sampler runs at 
    # 1 Hz, decimated with divisor 10 and pulse_no 3, will trigger at 3s, 13s, 23s 
    # and so on
    class DecimatedSampler
      extend Notify

      attr_reader :sample_time, :divisor, :pulse_no, :enable_signal
      notify :sample

      def initialize(sampler, divisor, options = {})
        @sampler, @divisor, @pulse_no = sampler, divisor, options[:pulse_no] || 0
        @sample_time = Analog.to_analog(sampler.sample_time) * divisor
        @sample_count = -@pulse_no
        @enable_signal = (options[:en] || true) && sampler.enabled_signal

        sampler.on_sample do
          notify_sample if @sample_count == 0 && enable_signal.v
          @sample_count = (@sample_count + 1) % divisor
        end
      end

      def running?
        @sampler.running?
      end
    end
  end
end






