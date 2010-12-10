require File.dirname(__FILE__) + '/lib/machines'

Dir['tasks/**/*.rake'].each { |t| load t }

desc "Look for TODO and FIXME tags in the code"
task :todo do
  FileList['**/*.rb'].egrep(/#.*(FIXME|TODO|TBD)/)
end


task :default => [:spec, :todo]
