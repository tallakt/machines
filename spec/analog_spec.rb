require File.dirname(__FILE__) + '/spec_helper.rb'
require 'ruby-plc/timedomain/analog'

include RubyPlc::TimeDomain


describe 'Analog signals' do
  before(:each) do
    @a = Analog.new 0.0
    @b = Analog.new 0.0
    @d = Discrete.new
  end

  it 'should report on change' do
    ok = nil
    @a.on_change { ok = :ok }
    @a.v = 5.0
    ok.should == :ok
    ok = nil
    @a.v = 10.0
    ok.should == :ok
  end

  it 'should not report when unchanged' do
    @a.v = 5.0
    @a.on_change { fail }
    @a.v = 5.0
  end

  it 'should be able to hold a real, int, nil and bool' do
    @a.v = 5.0
    @a.v.should == 5.0
    @a.v = 1
    @a.v.should == 1
    @a.v = nil
    @a.v.should be_nil
    @a.v = false
    @a.v.should be_false
  end

  it 'should support the + operation with another signal' do
    sum = @a + @b
    sum.v.should == 0.0
    @a.v = 1.0
    sum.v.should == 1.0
    @b.v = 1.0
    sum.v.should == 2.0
  end

  it 'should support the <=> operation with another signal' do
    cmp = @a <=> @b
    cmp.should be_a Analog
    cmp.v.should be_a Fixnum
    cmp.v.should == 0
    @a.v = 1.0
    cmp.v.should == (1.0 <=> 0.0)
    @b.v = 2.0
    cmp.v.should == (1.0 <=> 2.0)
   end

  it 'should support the + operation with another constant real value' do
    sum = @a + 5.0
    sum.should be_a Analog
    sum.v.should == 5.0
    @a.v = 1.0
    sum.v.should == 6.0
   end

  it 'should convert to a discrete value with the > operator' do
    disc = @a > 0.5
    disc.should be_a DiscreteBase
    disc.v.should be_false
    @a.v = 1.0
    disc.v.should be_true
    @a.v = -1.0
    disc.v.should be_false
  end

  it 'should support Analog.combine to make one signal out of many' do
    c = Analog.new 1.0
    comb = Analog.combine(@a, @b, c) do |a, b, c|
      a ** 2 + b ** 2 + c ** 2
    end
    comb.should be_a Analog
    @a.v = 2.0
    @b.v = 4.0
    comb.v.should be_close 1.0 ** 2 + 2.0 ** 2 + 4.0 ** 2, 0.0001
  end

  it 'should support Analog.to_disc with a block to convert to discrete' do
    disc = @a.to_disc {|a| (1.0..2.0).include? a }
    disc.should be_a DiscreteBase
    disc.v.should be_false
    @a.v = 1.5
    disc.v.should be_true
    @a.v = 2.5
    disc.v.should be_false
  end

  it 'should support Analog.combine to discrete to combine an analog, a discrete and a constant' do
    comb = Analog.combine(@a, @d, 5.0) do |a, d, c|
      a * 5.0 + (d ? 10.0 : 20.0) + c
    end
    @a.v = 3.0
    @d.v = true
    comb.v.should == 3.0 * 5.0 + 10.0 + 5.0
    @a.v = 2.0
    @d.v = false
    comb.v.should == 2.0 * 5.0 + 20.0 + 5.0
    comb.should be_a Analog
  end
end
