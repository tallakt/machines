class Heater < Machines::MachineBase
  def initialize
    modbus_io :remote_io_module, address => '127.0.0.1', default => true

    # Analog input signals
    @level = analog_in :mw1000, :description => 'Level transmitter', :max => 10.0, :unit => 'm'
    @pressure = analog_in :mw1001, :description => 'Tank pressure', :max => 50.0, :unit => 'bar'
    @temperature_tank = analog_in :mw1002, :description => 'Tank temperature', :max => 300.0, :unit => '°C'
    @temperature_discharge = analog_in :mw1003, :description => '', :max => 300.0, :unit => '°C'

    # Analog control signals
    @vapor_valve = analog_out :mw2000, :description => 'Vapor valve'
    @discharge_valve = analog_out :mw2001, :description => 'Discharge valve'
    @pump_speed = analog_out :mw2002, :description => 'Speed of inlet pump'

    # Assume that the process is started and stopped by two pushbuttons
    @start = digital_in :m3001, :description => 'Start button'
    @stop = digital_in :m3002, :description => 'Stop button'

    # Parameters
    @sp_temperature = setpoint :default => 150.0, :description => 'Setpoint temperature'
    @sp_hi_temperature = setpoint :default => 200.0, :description => 'High temperature limit'
    @sp_pressure = setpoint :default => 3.0, :description => 'Setpoint rank pressure'
    @sp_hi_pressure = setpoint :default => 5.0, :description => 'High pressure limit'
    @sp_level = setpoint :default => 3.0, :description => 'Setpoint level'
    @sp_hi_level = setpoint :default => 5.0, :description => 'High level limit'

    # Alarms
    @hi_temperature = alarm (@temperature_tank > @sp_hi_temperature.value).ton(5.seconds),
      :description => 'High temperature'
    @hi_pressure = alarm (@pressure > @sp_hi_pressure.value).ton(5.seconds),
      :description => 'High pressure'

    # Conditions to stop process
    @stop_condition = @hi_temperature | @hi_pressure | @stop

    # PID controllers
    @pid_pressure = PIDController.new 'Pressure controller' do |pid|
      pid.input = @pressure
      pid.output = @discharge_valve
      pid.p_setpoint = setpoint :default => 10.0
      pid.i_setpoint = setpoint :default => 10.seconds
      pid.sample_time 0.5.seconds
    end

    @pid_temperature = PIDController.new 'Temperature controller' do |pid|
      pid.input = @temperature_discharge
      pid.output = @vapor_valve
      pid.p_setpoint = setpoint :default => 1.0
      pid.i_setpoint = setpoint :default => 60.seconds
      pid.sample_time 0.5.seconds
    end

    # Startup sequence
    stack_sequence :auto_start => true do |seq|
      seq.step 'Initial step' do |step|
        step.on_enter { @pump_speed.v = 0.0; @vapor_valve.v = 0.0; @discharge_valve.v = 0.0 }
        step.continue_if @start & @stop_condition.not
      end

      seq.step_up 'Initial vapor heating' do |step|
        step.on_enter { @vapor_valve.v = 50.0 }
        step.continue_if @temperature_tank > @sp_temperature.value }
        step.timeout 10.minutes, 'No response from vapor heating'
      end

      seq.step @pid_pressure.start_step

      seq.step_up 'Initial pressure buildup' do |step|
        step.on_enter { @pump_speed.v = 30.0; @discharge_valve.v = 30.0 }
        step.continue_if @pressure > @sp_pressure.value
        step.timeout 1.minute, 'No pressure buildup'
      end

      seq.step @pid_temperature.start_step
      seq.step @pid_flow.start_step

      seq.step_up 'Process running' do |step|
        @running = step.active_signal
      end

      (seq.steps - seq.first_step).each {|step| step.continue_if @stop_condition, seq.first_step}
    end
  end
end
