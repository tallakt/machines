require 'machines/etc/notify'
require 'machines/timedomain/scheduler'
require 'rmodbus'
require 'struct'
require 'monitor'

module Machines
  module IO
    # All methods are assumed to perform in the Scvheduler current thread
    # Performing requests are done in private threads and when the results 
    # are ready, they are added to the queue of scheduled tasks in the 
    # Scheduler
    class ModbusSlave
      ModbusEntry = Struct.new :signal, :format, :scangroup

      notify :exception

      def initialize(options = {})
        @opts = {
          :port => 502,
          :host => 'localhost',
          :slave_address => 1,
          :bool_block_size => 128,
          :word_block_size => 128,
          :threads => 1
        }
        @opts.merge! options
        @connection = RModbus::TCPClient.new @opts[:host], @opts[:port], @opts[:slave_address]
        @bool_inputs = MultiRBTree.new
        @word_inputs = MultiRBTree.new
        @bool_outputs = MultiRBTree.new
        @word_outputs = MultiRBTree.new

        # Create a queue of Procs that call modbus functions in background
        queue = []
        queue.extend MonitorMixin
        @thread_tasks = {
          :queue => queue,
          :cond => queue.new_cond
        }

        # Start the background threads
        1.upto(@opts[:threads]) do
          Thread.start do
            @thread_tasks[:queue].synchronize do
              @thread_tasks[:cond].wait_while { @thread_tasks[:queue].empty? }
              begin
                @thread_tasks[:queue].shift.call
              rescue Exception => ex
                notify_exception ex
              end
            end
          end
        end
      end

      def input(address, options={})
        case type_from_address address
        when :int
          word_input address, options
        when :bool
          bool_input address, options
        end
      end

      def output(signal, address, options={})
        case type_from_address address
        when :int
          word_output signal, address, options
        when :bool
          bool_output signal, address, options
        end
      end

      def close
        @connection.close
      end


      def update(scangroup = :all)
        #TODO Should have an option to autoreset written bits
        #TODO Should frist write all output groups, then wait before reading
        #TODO For bool values written support options :only_re, :only_fe, :always, :only_change
        #TODO Must support buffering of writes for bool and int values :only_change/:always
        write_wrapper(@bool_outputs, scangroup) do |group|
          values = @bool_outputs.values_at(group).map {|v| v ? 1 : 0})
          @connection.write_multiple_coils(group.first, values)
        end

        write_wrapper(@word_outputs, scangroup) do |group|
          @connection.write_multiple_registers(group.first, @word_outputs.values_at(group))
        end

        read_wrapper(@bool_inputs, scangroup) do |group|
          values = @connection.read_multiple_coils(group.first, group.count)
          Scheduler.at_once do
            @bool_inputs.bound(group.first, group.last) do |address, entry|
              entry.signal.v = (values[address - group.first] == 0 ? false : true)
            end
          end
        end

        read_wrapper(@word_inputs, scangroup) do |group|
          values = @connection.read_multiple_registers(group.first, group.count)
          Scheduler.at_once do 
            @word_inputs.bound(group.first, group.last) do |address, entry|
              #TODO Only supporting :int as yet
              case entry.format
              when :int
                entry.signal.v = values[address - group.first]
              else
                throw RuntimeError.new 'Unsupported format :%s' % entry.format.to_s
            end
          end
        end
      end

      private

      def write_wrapper(entries, filter, &action) do
        consecutive_groups(filter_scangroup(entries, filter)).each do |group|
          perform_in_background do
            yield group
          end
        end
      end

      def read_wrapper(entries, filter, &action) do
        block_groups(filter_scangroup(entries, filter)).each do |group|
          perform_in_background do
            yield group
          end
        end
      end
          

      def filter_scangroup(entries, filter)
        # TODO filters :inputs, :outputs, :standard (nil)
        case filter
        when :all
          entries
        else
          MultiRBTree[entries.select {|en| en.scangroup == filter }]
        end
      end

      def consecutive_groups(entries)
        # Calc difference of addresses in list
        diff = []        
        entries.keys.each_cons(2) {|a| diff << a[1] - a[0] }
        
        # Remember indices where difference is not one
        gaps = [0]
        diff.each_with_index{|d, i| gaps << i unless d == 1 }
        gaps << k.size + 1

        # Create ranges for indices from one gap to the next
        result = []
        gaps.each_cons(2) do |a|
          result << a[0]..(a[1] - 1)
        end
        result
      end

      def block_groups(entries, max_block_size)
        result = []
        start = 0
        while start <= entries.last.first # last key
          start = entries.first.first # first key
          ub = entries.upper_bound start + max_block_size - 1
          result << start..ub
          start = entries.lower_bound(ub).first # next key after ub
        end
        result
      end

      def perform_in_background(&task) 
        @thread_tasks[:queue].synchronize do
          @thread_tasks[:queue] << task
          @thread_tasks[:cond].signal
        end
      end

      def bool_input(address, options)
        result = Machines::TimeDomain::DiscreteSignal.new
        @bool_inputs[number_from_address address] = 
          ModbusEntry.new result, :bool, options[:scangroup]
        result
      end

      def word_input(address, options)
        result = Machines::TimeDomain::AnalogSignal.new 
        @bool_inputs[number_from_address address] = 
          ModbusEntry.new result, options[:format] || :int, options[:scangroup]
        result
      end
      
      def bool_output(source, address, options)
        @bool_outputs[number_from_address address] = 
          ModbusEntry.new source, :bool, options[:scangroup]
        source
      end

      def word_output(source, address, options)
        @word_outputs[number_from_address address] = 
          ModbusEntry.new source, options[:format] || :int, options[:scangroup]
        source
      end

      def number_from_address(address)
        address.to_s.match(/\d+/)[0].to_i
      end

      def type_from_address(address)
        case address.to_s
        when /%?mw(\d+)/i
          :int
        when /%?m(\d+)/i
          :bool
        else
          throw RuntimeError.new 'Invalid format for address, use :mw1 or :m1'
        end
      end
    end
  end
end

