require 'ruby-plc/timedomain/analog.rb'

class Object
  def analog_attr(name)
    n = name.to_s
    module_eval <<-EOS
      def #{n}
        @#{n}
      end
      def #{n}=(value)
        @#{n} = Analog.to_analog value
      end
    EOS
  end
end


