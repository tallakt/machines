require 'rbtree'
require 'monitor'

module RubyPlc
  module TimeDomain
    class Scheduler
      class Entry
        attr_accessor :time, :tag, :callback
      end

      ZeroTime = Time.at(0)
      @@current = nil

      def initialize
        @scheduled = RBTree.new
        @scheduled.extend(MonitorMixin)
        @wait_cond = @scheduled.new_cond
        @running = false
        @work_queue = []
        @wait_policy = RealWaitPolicy.new
      end

      def Scheduler.current
        @@current ||= Scheduler.new
      end

      def Scheduler.dispose
        @@current.stop if @@current
        @@current = nil
      end


      def skip_waiting
        @wait_policy = SkipWaitPolicy.new
      end


      def wait_until(time, tag = nil, &block)
        throw RuntimeError.new 'wait_until will only accept Time objects' unless time.is_a? Time
        entry = Entry.new
        entry.time, entry.tag, entry.callback = time, tag, block
        @scheduled.synchronize do
          # TODO Check whether tag is already in use
          @scheduled[time] = entry
          @wait_cond.signal
        end
      end

      def wait(delay, tag = nil, &block)
        wait_until(now + delay, tag) do
          yield
        end
      end

      def cancel(tag)
        @scheduled.synchronize do
          @scheduled.delete_if {|k,v| v.tag === tag }
          @wait_cond.signal
        end
      end

      def at_once(&block)
        wait_until(now, :now) { block.call }
      end

      def run
        @running = true
        while @running 
          @scheduled.synchronize do
            timeout = nil
            if @scheduled.any?
              timeout = @scheduled.first.last.time - @wait_policy.now
              @wait_policy.wait_timeout @wait_cond, timeout
            else
              @wait_policy.wait @wait_cond
            end
          end
          work_if_busy
        end
      end

      def run_for(timeout)
        wait(timeout) { stop }
        run
      end

      def stop
        @running = false
        @scheduled.synchronize do
          @wait_cond.signal
        end
      end

      def now
        @wait_policy.now
      end

      private

      class RealWaitPolicy
        def wait_timeout(cond, timeout)
          cond.wait timeout if timeout > 0
        end

        def wait(cond)
          cond.wait
        end

        def now
          Time.now
        end
      end

      class SkipWaitPolicy
        def initialize 
          @time = Time.now
        end

        def wait_timeout(cond, timeout)
          @time += timeout if timeout > 0
        end

        def wait
          throw RuntimeError.new 'Waiting forever in skip wait policy'
        end

        def now
          @time
        end
      end

      def work_if_busy
        @scheduled.synchronize do
          t = @wait_policy.now
          while !@scheduled.empty? && @scheduled.first.last.time <= t
            @work_queue << @scheduled.shift.last.callback
          end
        end
        @work_queue.each {|c| c.call }
        @work_queue.clear
      end
    end
  end
end
