require 'rbtree'
require 'monitor'

module RubyPlc
  module TimeDomain
    class Sequencer
      class Entry
        attr_accessor :time, :tag, :callback
      end

      private @@wait_tree = RBTree.new
      @@wait_tree.extend(MonitorMixin)
      private @@wait_cond = @@wait_tree.new_cond
      private @@running = false
      private ZeroTime = Time.at(0)

      def Sequencer.wait_until(time, tag, &block)
        entry = Entry.new
        entry.time, entry.tag, entry.callback = time, tag, block
        @@wait_tree.synchronize do
          # TODO Check whether tag is already in use
          @@wait_tree[time] = entry
          @@wait_cond.signal
        end
      end

      def Sequencer.cancel(tag)
        @@wait_tree.synchronize do
          @@wait_tree.delete_if {|k,v| k.tag == tag }
          @@wait_cond.signal
        end
      end

      def Sequencer.at_once(&block)
        wait_until(ZeroTime, :now, block)
      end

      def Sequencer.run
        @@running = true
        while @@running 
          @@wait_tree.synchronize do
            timeout = nil
            if @@wait_tree.any?
              timeout = @@wait_tree.first - Time.now
              @@wait_cond.wait timeout if timeout > 0
            else
              @@wait_cond.wait
            end
          end
          work_if_busy
        end
      end


      def Sequencer.stop
        @@running = false
        @@wait_tree.synchronize do
          @@wait_cond.signal
        end
      end

      def Sequencer.now
        Time.now
      end

      private

      @@work_queue = []

      def Sequencer.work_if_busy
        @@wait_tree.synchronize do
          T = Time.now
          while @@wait_tree.first.time <= t
            @@work_queue << @@wait_tree.shift.callback
          end
        end
        @@work_queue.each {|c| c.call }
        @@work_queue.clear
      end
    end
  end
end
