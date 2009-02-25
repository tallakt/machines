require File.dirname(__FILE__) + '/spec_helper.rb'
require 'ruby-plc/etc/notify.rb'

class NotifyTestEmpty
  extend Notify
end

class NotifyTestOne
  extend Notify
  notify :one
end

class NotifyTestOneTwo
  extend Notify
  notify :one
  notify :two
end

#class NotifyTestTwo
#  extend Notify
#  notify :one, :two
#end



describe Notify do
  before(:each) do
    @empty = NotifyTestEmpty.new
    @one = NotifyTestOne.new
    @one_two = NotifyTestOneTwo.new
    # @two = NotifyTestTwo.new
  end

  it "should support the on_one method for adding listeners" do
    @one.on_one do
    end
  end

  it "should support the notify_one methos for informing listeners" do
    @one.notify_one
  end

  it "should call the callback method when notify is issued" do
    tmp = nil
    @one.on_one do
      tmp = true
    end
    @one.notify_one
    tmp.should be_true
  end

  it "should not call the callback in the wrong notification" do
    @one_two.on_two do
      violated 'This should not happen'
    end
    @one_two.notify_one
  end

  it "should support more than one listener" do
    @count = 0
    1.up_to 5 do
      @one.on_one { @count += 1 }
    end
    @one.notify_one
    @count.should equal(5)
  end

  it "should not misbehave if an exception is thrown by a listener" do
    test = nil
    @one.on_one { throw 'Boom!' }
    @one.on_one { @test = true }
    lambda { @one.notify_one }.should_not raise_error
    test.should be_true
  end

  it "should call handle_notify_exception if available" do
    test = nil
    @one.class_eval <<-EOF
      def handle_notify_exception(ex) do
        throw 'you heard me!'
      end
    EOF
    @one.on_one { throw 'BOOM' }
    lambda { @on_one.notify_one }.should raise_exception
  end
end
