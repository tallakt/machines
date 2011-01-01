require File.dirname(__FILE__) + '/spec_helper.rb'
require 'machines/timedomain/timer'
require 'em-spec/rspec'

include Machines::Timedomain

describe Timer do
  include EM::SpecHelper

  before(:each) do
    @t0 = Time.now
    @timer = Timer.new 1
  end

  it 'should run for the desired time then stop' do
    em 4 do
      @timer.start
      @timer.on_finish do
        puts 'JUHUUU'
        raise 'test'
        (Time.now - @t0).should be_close(1.0, 0.010)
        raise 'test'
      end
    end
  end

  it 'should report the elapsed time' do
    em 1.5 do
      EM::add_timer 0.5 do
        @timer.elapsed.should be_close(0.5, 0.010)
        done
      end
      @timer.start
    end
  end


  it 'should report active and idle' do
    em 3.0 do
      EM::add_timer 0.5 do
        @timer.should_not be_active
        @timer.should be_idle

        EM::add_timer 0.5, proc { @timer.start }

        EM::add_timer 0.5 do
          @timer.should be_active
          @timer.should_not be_idle


          EM::add_timer 1.0 do
            @timer.should_not be_active
            @timer.should be_idle
            done
          end
        end
      end
      @timer.start
    end
  end

  it 'should not finish if beeing reset during timing' do
    timer.on_finish { fail }
    em 2.0 do
      EM::add_timer 0.5, proc { @timer.reset }
      EM::add_timer 1.5, proc { done }
      @timer.start
    end
  end

  it 'should accept changes in time while running' do
    time = Analog.new 1.0
    timer = Timer.new t
    times = [1.0, 3.0, 7.0]

    em 10.0 do
      timer.on_finish do
        (Time.now - @t0).should be_close(time.shift, 0.01)
        if times.empty?
          done
        else
          timer.start
        end
      end
      EM::add_timer 1.5, proc { time.v = 2.0 }
      EM::add_timer 3.5, proc { time.v = 4.0 }
      timer.start
    end
  end
end



