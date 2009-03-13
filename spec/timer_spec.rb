require File.dirname(__FILE__) + '/spec_helper.rb'
require 'machines/timedomain/timer'

include Machines::TimeDomain

describe Timer do
  before(:each) do
    Scheduler.current.skip_waiting
    @t0 = Scheduler.current.now
    @timer = Timer.new 1
  end

  after(:each) do
    Scheduler.dispose
  end

  it 'should run for the desired time then stop' do
    timer_finished = false
    @timer.start
    Timeout::timeout(2) do 
      @timer.on_finish do
        timer_finished = true
        (Scheduler.current.now - @t0).should be_close(1.0, 0.010)
      end
      Scheduler.current.run_for 1.5
    end
    timer_finished.should be_true
  end

  it 'should report the elapsed time' do
    Scheduler.current.wait 0.5 do
      @timer.elapsed.should be_close(0.5, 0.010)
    end
    @timer.start
    Scheduler.current.run_for 1.5
  end

  class BeLogicalFalse
    def matches?(target)
      @target = target
      !target
    end
    def failure_message
      "expected #{@target.inspect} to be logical false (false or nil)"
    end
    def negative_failure_message
      "expected #{@target.inspect} not to be logical false (any value but false or nil)"
    end
  end

  def be_logical_false
    BeLogicalFalse.new
  end

  it 'should report active and idle' do
    Scheduler.current.wait 0.5 do
      @timer.active?.should be_logical_false
      @timer.idle?.should be_true
    end
    Scheduler.current.wait 1 do
      @timer.start
    end
    Scheduler.current.wait 1.5 do
      @timer.active?.should be_true
      @timer.idle?.should be_logical_false
    end
    Scheduler.current.wait 2.5 do
      @timer.active?.should be_logical_false
      @timer.idle?.should be_true
    end
    Scheduler.current.run_for 3
  end

  it 'should not finish if beeing reset during timing' do
    Scheduler.current.wait 0.5 do
      @timer.reset
    end
    @timer.start
    @timer.on_finish { fail }
    Scheduler.current.run_for 1.5
  end

  it 'should accept changes in time while running' do
    Scheduler.current.wait 0.5 do
      @timer.time = 2
    end
    @timer.start
    @timer.on_finish { (Scheduler.current.now - @t0).should be_close(2.0, 0.010) }
    Scheduler.current.run_for 3.0
  end

  # TODO Must enable and write this spec
#  it 'should support an Analog as time input' do
#    fail
#  end

end



