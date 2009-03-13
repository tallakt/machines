require File.dirname(__FILE__) + '/spec_helper.rb'
require 'ruby-plc/sequences/step_base'
require 'ruby-plc/sequences/step'

include RubyPlc::Sequences
include RubyPlc::TimeDomain

describe StepBase do
  before(:each) do
    @dummy = Step.new
    @s = Step.new
    @fail_a = Step.new do |s|
      s.on_enter { fail }
    end
    @fail_b = Step.new do |s|
      s.on_enter { fail }
    end
    Scheduler.current.skip_waiting
    @t0 = Scheduler.current.now
    # pulses at 1, 2, 3, 4 seconds
    @puls = {}
    (1..4).each do |i|
      p = Discrete.new
      @puls[i] = p
      at(i) { p.v = true }
    end
    @p1, @p2, @p3, @p4 = @puls
  end

  after(:each) do
    Scheduler.dispose
  end

  def at(time, &block)
    Scheduler.current.wait(time, &block)
  end

  def now
    Scheduler.current.now - @t0
  end

  def expect_now(t)
    now.should be_close t, 0.010
  end

  def run
    Scheduler.current.run_for 5
  end

  it 'should have an active signal' do
    @s.continue_if @p2, @dummy
    act = @s.active_signal
    act.should be_a DiscreteBase
    act.v.should be_false
    at(1.0) { @s.start }
    at(1.5) { act.v.should be_true }
    at(2.5) { act.c.should be_false }
  end

  it 'should report when finished? as well as active?' do
    @s.continue_if @p1, @dummy
    at(0.1){ @s.should_not be_active; @s.should be_finished }
    at(0.2){ @s.start }
    at(0.3){ @s.should be_active; @s.should_not be_finished }
    at(1.1){ @s.should_not be_active; @s.should be_finished }
    run
  end

  it 'should callback on enter, exit' do
    count = 0
    @s.continue_if @p2, @dummy
    at(1.0){ @s.start }
    @s.on_enter { expect_now 1.0; count += 1 }
    @s.on_exit { expect_now 2.0; count += 1 }
    @s.on_exit_reset { expect_now 2.0; count += 1 }
    count.should == 3
    run
  end

  it 'should callback on enter, regardless of whether it continues to next step' do
    count = 0
    @s.continue_to @dummy
    at(1.0){ @s.start }
    @s.on_enter { expect_now 1.0; count += 1 }
    @s.on_exit { expect_now 1.0; count += 1 }
    @s.on_exit_reset { expect_now 1.0; count += 1 }
    count.should == 3
    run
  end

  it 'should callback on exit, but not before active signal is off' do
    @s.continue_if @p1, @dummy
    at(1.0){ @s.start }
    @s.on_exit { @s.should be_active }
    run
  end

  it 'should continue immediately if no conditions are defined' do
    ok = nil
    @s.continue_to @dummy
    at(1.0){ @s.start }
    @s.on_exit { expect_now 1.0; ok = :ok }
    run
    ok.should == :ok
  end

  it 'should not continue before exit contitions are true' do
    @s.continue_if @p2, @dummy
    at(1.0){ @s.start }
    at(1.5){ @s.should be_active }
    at(2.5){ @s.should be_finished }
    run
  end

  it 'should continue to next step on otherwise condition' do
    @s.continue_if @p2, @fail_a
    @s.continue_if false, @fail_b
    @s.otherwise @dummy
    at(1.0){ @s.start }
    at(1.5){ @s.should be_active }
    at(2.5){ @s.should be_finished }
    run
  end

  it 'should continue to next step in precense of otherwise condition' do
    @s.continue_if @p2.invert, @dummy
    @s.continue_if false, @fail_b
    @s.otherwise @fail_a
    at(1.0){ @s.start }
    at(1.5){ @dummy.should be_active }
    run
  end

  it 'should continue to correct step if continue_to has been assigned' do
    @s.continue_to @dummy
    @s.default_next_step = @fail_a
    at(1.0){ @s.start }
    at(1.5){ @dummy.should be_active }
    run
  end

  it 'should continue to correct step if continue_from has been assigned' do
    @dummy.continue_from @s
    @s.default_next_step = @fail_a
    at(1.0){ @s.start }
    at(1.5){ @dummy.should be_active }
    run
  end

  it 'should not continue if there are no otherwise conditions among conditions' do
    @s.default_next_step = @dummy
    @s.continue_if false, @fail_a
    @s.continue_if @p1.invert, @fail_b
    at(2.0){ s.start }
    run
    @s.should be_running
  end

  it 'should report the correct duration' do
    at(1.0){ @s.start }
    at(1.1){ @s.duration.should be_close(0.1, 0.010) }
    at(4.0){ @s.duration.should be_close(3.0, 0.010) }
    run
  end

  it 'should reset' do
    at(1.0){ @s.start }
    at(2.0){ @s.reset }
    at(2.1){ @s.should be_finished }
    run
  end

  it 'should report correct startup time' do
    at(1.0){ @s.start }
    at(2.0){ @s.start_time.to_f.should be_close(@t0.to_f + 1.0, 0.010) }
    run
  end

  it 'should continue immediately if exit condition is already true' do
    @s.continue_if @p1, @dummy
    at(2.0){ @s.start }
    at(2.1){ @s.should be_finished }
    at(2.1){ @dummy.should be_running }
    run
  end

  it 'should only continue on method call when continue_on_callback is used' do
    @s.default_next_step = @dummy
    @s.continue_on_callback
    at(1.0){ @s.start }
    at(1.5){ @s.should be_running }
    at(2.0){ @s.continue }
    at(2.5){ @dummy.should be_running }
    at(2.5){ @s.should be_finished }
    run
  end

  it 'should contine to default next step on continue_if without step parameter' do
    @s.default_next_step = @dummy
    @s.continue_if @p2
    at(1.0){ @s.start }
    at(1.5){ @s.should be_running }
    at(1.5){ @dummy.should be_finished }
    at(2.5){ @dummy.should be_running }
    at(2.5){ @s.should be_finished }
    run
  end

  it 'should overlap the active signal of two consequitive states' do
    fail
  end
end

