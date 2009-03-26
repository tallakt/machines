require File.dirname(__FILE__) + '/spec_helper.rb'
require 'machines/timedomain/discrete'
require 'machines/timedomain/discrete_sink'

include Machines::Timedomain


describe 'Discrete signals' do
  before(:each) do
    @a = Discrete.new
    @b = Discrete.new
    Scheduler.current.skip_waiting
    @t0 = Scheduler.current.now

    # signal with two pulses at 1 sec and 4 sec, each 1 sec duration
    @double_pulse = create_pulse_train [1, 2, 4, 5]
   end

  after(:each) do
    Scheduler.dispose
  end

  def create_pulse_train(times)
    Discrete.new.tap do |p|
      times.each_slice(2) do |pair|
        Scheduler.current.wait(pair.first) { p.v = true }
        Scheduler.current.wait(pair.last) { p.v = false }
      end
    end
  end

  def check_time_offsets(times, desired_times)
    times.should have(desired_times.size).items
    times.zip(desired_times).each do |pair|
      pair.first.to_f.should be_close(pair.last.to_f, 0.010)
    end
  end

  def now
    Scheduler.current.now - @t0
  end


  it 'should notify on rising edge' do
    cc = nil
    @a.v = false
    @a.on_re { cc = :ok }
    @a.on_fe { fail }
    @a.v = true
    cc.should == :ok
  end

  it 'should notify on falling edge' do
    cc = nil
    @a.v = true
    @a.on_fe { cc = :ok }
    @a.on_re { fail }
    @a.v = false
    cc.should == :ok
  end

  it 'should notify on change' do
    cc = []
    @a.v = true
    @a.on_change { cc << :ok }
    @a.v = false
    @a.v = true
    cc.should == [:ok, :ok]
  end

  it 'should not notify on no change' do
    @a.v = true
    @b.v = false
    [@a, @b].each do |x|
      x.on_re { fail }
      x.on_fe { fail }
      x.on_change { fail }
    end
    @a.v = true
    @a.v = 1
    @b.v = false
    @b.v = nil
  end

  it 'should support the and operation' do
    cc = nil
    @a.v = false
    @b.v = false
    c = @a & @b
    c.on_re { cc = :ok }

    c.v.should be_false
    @a.v = true
    c.v.should be_false
    cc.should be_nil
    @b.v = true
    c.v.should be_true
    cc.should == :ok
    @a.v = false
    c.v.should be_false
  end

  it 'should support the or operation' do
    cc = nil
    @a.v = false
    @b.v = false
    c = @a | @b
    c.on_re { cc = :ok }

    c.v.should be_false
    @a.v = true
    c.v.should be_true
    cc.should == :ok
    @b.v = true
    c.v.should be_true
    @a.v = false
    c.v.should be_true
    @b.v = false
    c.v.should be_false
    end

  it 'should support timed on with a block' do
    times = []
    @double_pulse.ton(0.5) { times << now }
    @double_pulse.ton(2) { fail }
    Scheduler.current.run_for 10
    check_time_offsets(times, [1.5, 4.5]);
  end

  it 'should support timed off with a block' do
    times = []
    @double_pulse.tof(1).should be_a DiscreteBase
    @double_pulse.tof(1) { times << now }
    @double_pulse.tof(7) { fail }
    Scheduler.current.run_for 10
    check_time_offsets(times, [3, 6]);
  end

  it 'should support timed on returning a signal' do
    times = []
    @double_pulse.ton(1).should be_a DiscreteBase
    @double_pulse.ton(0.5).on_change { times << now }
    @double_pulse.ton(2).on_change { fail }
    Scheduler.current.run_for 20000
    check_time_offsets(times, [1.5, 2, 4.5, 5]);
  end

  it 'should support timed off returning a signal' do
    times = []
    @double_pulse.tof(1).should be_a DiscreteBase
    @double_pulse.tof(1).on_change { times << now }
    @double_pulse.tof(7).on_change { fail }
    Scheduler.current.run_for 10
    check_time_offsets(times, [1, 3, 4, 6]);
  end

  it 'should allow to sink from another discrete' do
    times = []
    sink = DiscreteSink.new
    sink.sink @double_pulse
    sink.on_change { times << now }
    # TODO Sampler to check continous that values are the same
    Scheduler.current.run_for 10
    check_time_offsets(times, [1, 2, 4, 5]);
  end

  it 'should should allow sink from another constant value' do
    sink = DiscreteSink.new
    sink.sink(false)
    sink.v.should be_false

    sink = DiscreteSink.new
    sink.sink(true)
    sink.v.should be_true

    sink = DiscreteSink.new(true)
    sink.v.should be_true
  end

  it 'should be illegal to assign multiple times to a sink' do
    sink = DiscreteSink.new
    sink.sink(false)
    lambda { sink.sink(true) }.should raise_error
  end

  it 'should return nil from an empty sink' do
    DiscreteSink.new.v.should be_nil
  end

  it 'should generate the inverse discrete signal' do
    i = @double_pulse.invert
    i.should be_a DiscreteBase
    (0..6).each do |t|
      Scheduler.current.wait(t + 0.5) { i.v.should == !@double_pulse.v }
    end
    Scheduler.current.run_for 10
  end
end
