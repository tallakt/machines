require 'machines/etc/notify'
require 'machines/timedomain/scheduler'
require 'rmodbus'
require 'monitor'

module Machines
  module IO
    # All methods are assumed to perform in the Scheduler current thread
    # Performing requests are done in private threads and when the results 
    # are ready, they are added to the queue of scheduled tasks in the 
    # Scheduler
    class ActAsModbusSlave
      extend Notify

      ModbusEntry = Struct.new :signal, :format, :scangroup, :length

      notify :exception

      def initialize(options = {})
        #TODO timeout values?
        @opts = {
          :port => 502,
          :host => 'localhost',
          :slave_address => 1,
          :bool_block_size => 128,
          :word_block_size => 128,
          :threads => 1
        }
        @opts.merge! options
        @bool_inputs = MultiRBTree.new
        @word_inputs = MultiRBTree.new
        @bool_outputs = MultiRBTree.new
        @word_outputs = MultiRBTree.new

        # Create a queue of Procs that call modbus functions in background
        queue = []
        queue.extend MonitorMixin
        @tasks = {
          :queue => queue,
          :cond => queue.new_cond
        }
      end

      def start
        # Start the background threads
        @stopping = false
        @threads = (1..@opts[:threads]).collect do
          Thread.start do
            communication_thread_start
          end
        end
        self
      end


      def stop
        @tasks[:queue].synchronize do
          @stopping = true
          @tasks[:cond].broadcast
        end
        @threads.each {|t| t.wakeup.join }
        self
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

      def update(filter = :all)
        #TODO Should have an option to autoreset written bits
        #TODO Should frist write all output groups, then wait before reading
        #TODO For bool values written support options :only_re, :only_fe, :always, :only_change
        #TODO Must support buffering of writes for bool and int values :only_change/:always
        #FIXME Bug since values must be read from the signals in main thread, FIXED, TEST!
        values_generator = Proc.new do |group| 
          @bool_outputs.values_at(group).map {|v| v ? 1 : 0}
        end
        update_helper(@bool_outputs, filter, :consecutive_groups, values_generator) do |group, conn, values|
          conn.write_multiple_coils(group.first, values)
        end

        values_generator = Proc.new do |group| 
          @bool_outputs.values_at(group)
        end
        update_helper(@word_outputs, filter, :consecutive_groups, values_generator) do |group, conn, values|
          conn.write_multiple_registers(group.first, values)
        end

        update_helper(@bool_inputs, filter, :block_groups) do |group, connection|
          values = connection.read_multiple_coils(group.first, group.count)
          Scheduler.at_once do
            @bool_inputs.bound(group.first, group.last) do |address, entry|
              entry.signal.v = (values[address - group.first] == 0 ? false : true)
            end
          end
        end

        update_helper(@word_inputs, filter, :block_groups) do |group, connection|
          values = connection.read_multiple_registers(group.first, group.count)
          Scheduler.at_once do 
            @word_inputs.bound(group.first, group.last) do |address, entry|
              handle_word_data(address - group.first, entry, values)
            end
          end
        end
      end

      private

      def handle_word_data(address, entry, raw_data)
        #TODO Only supporting :int as yet
        case entry.format
        when :int
          entry.signal.v = values[address]
        when :uint
          entry.signal.v = values[address] & 0xffff
        when :long
          entry.signal.v = values.values_at(address..(address+1)).pack('u*').unpack('i')
        when :float
          entry.signal.v = values.values_at(address..(address+1)).pack('u*').unpack('g')
        when :string
          throw RuntimeError.new 'No :length supplied for string value' unless entry.length
          entry.signal.v = values.values_at(address..(address + entry.length)).pack('u*')
        else
          throw RuntimeError.new 'Unsupported format :%s' % entry.format.to_s
        end
      end

      def update_helper(entries, filter, group_method, val_generator = nil)
        send(group_method, filter_scangroup(entries, filter)).each do |group|
          values = val_generator && val_generator.call(group)
          perform_in_background do |connection|
            if values
              yield group, connection, values
            else
              yield group, connection
            end
          end
        end
      end

      def filter_scangroup(entries, filter)
        # TODO filters :inputs, :outputs, :standard (nil), :constants
        case filter
        when :all
          entries
        else
          MultiRBTree[entries.select {|en| en.filter == filter }]
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
        @tasks[:queue].synchronize do
          @tasks[:queue] << task
          @tasks[:cond].signal
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
          ModbusEntry.new result, options[:format] || :int, options[:scangroup], options[:length]
        result
      end
      
      def bool_output(source, address, options)
        addr = number_from_address address
        if @bool_outputs.key? addr 
          throw RuntimeError.new 'Output on bool address %d is already in use' % addr 
        end
        @bool_outputs[addr] = ModbusEntry.new source, :bool, options[:scangroup]
        source
      end

      def word_output(source, address, options)
        addr = number_from_address address
        if @word.key? addr 
          throw RuntimeError.new 'Output on word address %d is already in use' % addr 
        end
        @word_outputs[addr] = 
          ModbusEntry.new source, options[:format] || :int, options[:scangroup], options[:length]
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

      def communication_thread_start
        begin
          connection = RModbus::TCPClient.new @opts[:host], @opts[:port], @opts[:slave_address]
          @tasks[:queue].synchronize do
            @tasks[:cond].wait_while { @tasks[:queue].empty? && !@stopping}
            begin
              @tasks[:queue].shift.call(connection) unless @stopping
            rescue Exception => ex
              notify_exception ex
            end
          end
        rescue Exception => ex
          notify_exception ex
          sleep(10.0 + 5.0 * rand)
        end until @stopping
      end
    end
  end
end

