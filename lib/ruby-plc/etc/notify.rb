module Notify
  @debug = nil
  class<<self
    # force Notification to show up in stack backtraces of delegated methods
    attr_accessor :debug
  end

  def notify(name)
    n = name.to_s
    listeners = "@notify_#{n}_listeners" 
    module_eval(<<-EOS, '(__NOTIFICATION__)', 1)
      #{listeners} = nil

    
      def notify_#{n}
        exceptions = nil
        if #{listeners}
          #{listeners}.each do |l|
            begin
              |l| l.call
            rescue Exception => ex
              $@.delete_if{|s| /^\\(__NOTIFICATION__\\):/ =~ s} unless Notification::debug
              exceptions ||= []
              exceptions << ex
            end
          end
          if exceptions && respond_to? :handle_notify_exception
            handle_notify_exception(exceptions)
          end
        end
      end
      
      def on_#{n}(&proc)
        #{listeners} ||= []
        #{listeners} << proc
      end

      private :notify_#{n}
    EOS
  end
end

