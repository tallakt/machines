module Notify
  def notify(*names)
    names.each do |name|
      n = name.to_s
      listeners = "@notify_#{n}_listeners" 
      module_eval <<-EOS
        #{listeners} = nil

      
        def notify_#{n}(*args)
          errors = nil
          if #{listeners}
            #{listeners}.each do |l|
              begin
                l.call(*args)
              rescue Exception => ex
                errors ||= []
                errors << ex
              end
            end
            if errors && respond_to?(:handle_notify_error)
              handle_notify_error(errors)
            end
          end
        end
        
        def on_#{n}(&proc)
          #{listeners} ||= []
          #{listeners} << proc
        end
      EOS
    end
  end
end

