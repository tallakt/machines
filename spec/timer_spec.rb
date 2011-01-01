require File.dirname(__FILE__) + '/spec_helper.rb'
require 'machines/timedomain/timer'
require 'em-spec/rspec'

include Machines::Timedomain

describe Machines::Timedomain::Timer do
  include EM::SpecHelper

  before(:each) do
    @t0 = Time.now
  end


  def elapsed
    #puts (Time.now - @t0).to_s + ' <-- elapsed'
    Time.now - @t0
  end

  it 'should run for the desired time then stop' do
    timer = Timer.new 0.1
    em 1.0 do
      timer.start
      timer.on_finish do
        elapsed.should be_close(0.1, 0.1)
        done
      end
    end
  end

  it 'should report the elapsed time' do
    timer = Timer.new 1.0
    timer.start
    em 1.0 do
      EM::add_timer 0.5 do
        timer.should be_active
        timer.elapsed.should be_close(0.5, 0.1)
        done
      end
    end
  end


  it 'should report active and idle' do
    timer = Timer.new 0.2
    em 1.0 do
      EM::add_timer 0.1 do
        timer.should_not be_active
        timer.should be_idle

        timer.start

        EM::add_timer 0.1 do
          timer.should be_active
          timer.should_not be_idle


          EM::add_timer 0.2 do
            timer.should_not be_active
            timer.should be_idle
            done
          end
        end
      end
    end
  end

  it 'should not finish if beeing reset during timing' do
    timer = Timer.new 0.5
    timer.on_finish { fail }
    em 1.0 do
      EM::add_timer 0.1, proc { timer.reset }
      EM::add_timer 0.8, proc { done }
      timer.start
    end
  end

  it 'should accept changes in time while running' do
    param = Analog.new 0.4
    timer = Timer.new param
    times = [0.4, 1.0, 1.5]

    em 2.0 do
      timer.on_finish do
        elapsed.should be_close(times.shift, 0.1)
        done if times.empty?
        timer.start
      end
      EM::add_timer 0.6, proc { param.v = 0.6 }
      EM::add_timer 1.2, proc { param.v = 0.5 }
      timer.start
    end
  end

  it 'should not start by itself' do
    timer = Timer.new 0.1
    em 1.0 do
      EM::add_timer 0.5, proc { done }
      timer.on_finish { fail }
    end
  end

  it 'may be started outside the EM loop and inside' do
    t0 = Timer.new 0.1
    t1 = Timer.new 0.4
    t0.start
    em 1.0 do
      t0.on_finish { elapsed.should be_close(0.1, 0.1) }
      t1.on_finish { elapsed.should be_close(0.5, 0.2); done }
      EM::add_timer(0.1) { t1.start }
    end
  end
end



