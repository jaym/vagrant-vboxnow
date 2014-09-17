begin
  require 'vagrant'
rescue LoadError
  raise 'This plugin must run within vagrant'
end

require 'vagrant-vboxnow/plugin'
