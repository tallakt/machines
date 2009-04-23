require File.dirname(__FILE__) + '/spec_helper.rb'
require 'machines/io/act_as_modbus_slave'

include Machines::IO

describe ActAsModbusSlave do
  before(:each) do
  end

  it 'should create a RModbus connection with parametered address, port, slave id' do
    ModBus::TCPClient.should_receive(:new).with('test_addr', 99, 5)
    m = ActAsModbusSlave.new :address => 'test_addr', :port => 99, :slave_id => 5, :threads => 1
    m.start
    m.stop
  end

  it 'should start the correct number of threads according to paramter' do
    Thread.should_receive(:start).twice
    ActAsModbusSlave.new(:threads => 2).start.stop
  end

  it 'should update a input bool' do
    fail
  end

  it 'should update a input word' do
    fail
  end

  it 'should update a output bool' do
    fail
  end

  it 'should update a output word' do
    fail
  end

  it 'should notify about exceptions when sending messages' do
    fail
  end

  it 'should notify about exceptions when unable to connect to master' do
    fail
  end

  it 'should reconnect to modbus server after disconnect' do
    fail
  end

  it 'should only update the signals in the correct scangroup' do
    fail
  end

  it 'should be able to update :inputs and :outputs' do
    fail
  end

  it 'should group inputs and outputs correctly' do
    fail
  end

  it 'should correctly read ints, uints, floats, strings and other formats' do
    fail
  end

  it 'should report an exception on unknown data types' do
    fail
  end

end



