module Vagrant
  module VBoxNow
    class Plugin < Vagrant.plugin('2')
      name 'vagrant-vboxnow'

      action_hook('monkey_vbox_import', :machine_action_up) do |hook|
        require_relative 'action/monkey'
        hook.before(VagrantPlugins::ProviderVirtualBox::Action::Import, Vagrant::VBoxNow::Action::MonkeyPatchImportAction)
      end
    end
  end
end
