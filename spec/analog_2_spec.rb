require File.dirname(__FILE__) + '/spec_helper.rb'
require 'machines/timedomain/analog_value'

include Machines::Timedomain


describe 'Analog signals' do
  before(:each) do
    @a = AnalogValue.new 0.0
    @b = AnalogValue.new 0.0
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

end
