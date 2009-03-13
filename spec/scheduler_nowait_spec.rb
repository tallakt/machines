require File.dirname(__FILE__) + '/spec_helper.rb'
require 'ruby-plc/timedomain/scheduler.rb'
require 'benchmark'
require 'timeout'

include RubyPlc::TimeDomain

describe Scheduler do
  before(:each) do
    Scheduler.current.skip_waiting
    @t0 = Scheduler.current.now
  end

  after(:each) do
    Scheduler.dispose
  end

  it 'should throw an exception if nothing happens' do
    Timeout::timeout(2) do 
      lambda { Scheduler.current.run }.should raise_error
    end
  end

  it 'should not actually perform a wait that takes time' do
    Benchmark.measure { Scheduler.current.run_for 1 }.real.should be_close(0.0, 0.010)
  end

  it 'should callback after the correct amount of time using wait_until' do
    Scheduler.current.wait_until(@t0 + 10) do
      (Scheduler.current.now - @t0).should be_close(10.0, 0.010)
    end
    Scheduler.current.run_for 11
  end

  it 'should callback after the correct amount of time using wait' do
    Scheduler.current.wait(10) do
      (Scheduler.current.now - @t0).should be_close(10.0, 0.010)
    end
    Scheduler.current.run_for 11
  end

  it 'should execute run_now blocks immediately' do
    Scheduler.current.at_once do
      (Scheduler.current.now - @t0).should be_close(0.0, 0.010)
    end
    Scheduler.current.run_for 1
  end

  it 'should not callback if cancelled' do
    Scheduler.current.wait(10, :tag) do
      lambda { throw RuntimeException.new 'Should be cancelled' }.should_not raise_error
    end
    Scheduler.current.cancel :tag
    Scheduler.current.run_for 11
  end

  it 'should schedule callbacks in correct order at correct time' do
    times = []
    (1..10).each do |time|
      Scheduler.current.wait time do 
        times << Scheduler.current.now
      end
    end
    Scheduler.current.run_for 11
    dt = times.map {|t| t - @t0 }
    dt.each_with_index {|t, i| t.should be_close(i + 1, 0.010) }
  end

  def perform_foo(arr, foo)
    arr << foo
    Scheduler.current.wait 2 do
       perform_foo(arr, foo)
    end
  end

  it 'should schedule tasks correctly that were scheduled during runtime' do
    arr = []
    Scheduler.current.wait 2 do
      perform_foo arr, :foo
    end
    Scheduler.current.wait 1 do
      perform_foo arr, :bar
    end
    Scheduler.current.run_for 6.5
    arr.should eql([:bar, :foo] * 3)
  end

  it 'should execute a task immediately when time is in the past' do
    Scheduler.current.wait_until(@t0 - 10) do
      (Scheduler.current.now - @t0).should be_close(0.0, 0.010)
    end
    Scheduler.current.run_for 1
  end

  it 'should return a Time object from the now function' do
    Scheduler.current.now.should be_a(Time)
  end

  it 'should respond to many different events at the same time' do
    t = Scheduler.current.now + 0.5
    count = 0
    (1..100).each do
      Scheduler.current.wait_until(t) { count += 1 } 
    end
    Scheduler.current.wait_until t do
      count += 2
      count -= 1
    end
    Scheduler.current.run_for 1
    count.should == 101
  end
end


