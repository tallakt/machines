

class GarageDoor
  def initialize(number, signals)
    Sequence.new :auto_start => true do |q|
      # define steps
      rest = q.step "Initial step" 
      opening = q.step "Opening"
      closing = q.step "Closing"

      # Add names to IO list
      signals[:open_button].name = 'Open button door %d' % number
      signals[:close_button].name = 'Close button door %d' % number
      signals[:open_output].name = 'Open valve Y%d door %d' % [number * 2 - 1, number]
      signals[:close_output].name = 'Close valve Y%d door %d' % [number * 2, number]

      # define transitions
      [opening, closing].each do |s| 
        s.continue_to rest
        s.continue_if signals[:local]
        s.continue_if signals[:open_button]
        s.continue_if signals[:close_button]
      end

      rest.continue_if signals[:open_button] & signals[:local].inv, opening
      rest.continue_if signals[:close_button] & signals[:local].inv, closing

      opening.continue_after signals[:open_time]
      closing.continue_after signals[:close_time]


      # Define behaviour in steps
      signals[:open_output].sink opening.active_signal
      signals[:close_output].sink closing.active_signal

      # Activity signal
      @activity = opening.active_signal | closing.active_signal
    end

    def activity? 
      @activity
    end
  end
end


class GarageDoorsApp extend MachinesApp
  io_connection :io, AdvantysStb.new('127.0.0.1') do |adv|
    adv.di16, 2
    adv.do16, 3
    adv.di16, 4
    adv.do16, 5
  end

  def initialize
    common = {
      :close_time => AnalogSignal.new(45.0),
      :open_time => AnalogSignal.new(55.0),
      :local => io.at :i3_2, 'Local mode selected'
    }

    # initialize garage doors with correct IO assignment
    open_buttons = deal_io :i, 1, 0..8
    close_buttons = deal_io(:i, 1, 9..15) + deal_io(:i, 3, 0..1)
    valve_outputs = deal_io(:q, 2, 0..11) + deal_io(:q, 4, 0..5)
    doors = (1..9).map do |n|
      GarageDoor.new n, common.merge(
        { :open_button => open_buttons.shift,
          :close_button => close_buttons.shift,
          :open_output =_ valve_outputs.shift,
          :close_output =_ valve_outputs.shift,
        })
    end

    # Initialize IO for hydraulic pump
    prv = io.at :q4_7, 'Pressure relief valve'
    hpo = io.at :i1_9, 'High temperature hydr oil (normally closed)'
    llo = io.at :i1_9, 'Low level hydr oil (normally closed)'

    # Logic for hydraulic pump
    any_activity = doors.inject {|sig, door| sig | door.activity? }
    prv.sink any_activity.tof(5.0) & hpo.not & llo.not
  end

  def deal_io(type, slot, terminals)
    terminals.map {|t| io.at '%s%d_%d' % [typei.to_s, slot, t] }
  end
end
