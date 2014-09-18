# vagrant-vboxnow
A [Vagrant](http://www.vagrantup.com/) to speed up creation of VirtualBox VMs.

## How
This plugin can speed up VM creation by not doing a full import each time. The vmdk
files are imported once. Then, a snapshot is created, and each new vim is a linked
clone to that one.

Using VBoxManage, this looks something like

$ VBoxManage import ~/.vagrant.d/boxes/box_name/0/virtualbox/box.ovf --vsys 0 --vmname test1
$ VBoxManage snapshot test1 take ts
$ VBoxManage clonevm test1 --snapshot tsn --options link --name test1_clone --registe

## Installation

Add the following to your gemfile

```ruby
group :plugins do
  gem "vagrant-vboxnow", git: "https://github.com/jdmundrawala/vagrant-vboxnow.git"
end
```

And then execute:

    $ bundle

## Usage
bundle exec vagrant up

# Performance
* Without vagrant-vboxnow
```
jaym@angry_dome ~/workspace/vagrant-vboxnow[default]  [master *]
Â± % time vagrant up                                                                                                                                                                                                                                                       !10207
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'kensykora/windows_2012_r2_standard'...
==> default: Matching MAC address for NAT networking...
==> default: Setting the name of the VM: vagrant-vboxnow_default_1411011919657_65516
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 3389 => 3389 (adapter 1)
    default: 22 => 2222 (adapter 1)
    default: 5985 => 55985 (adapter 1)
==> default: Running 'pre-boot' VM customizations...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
==> default: Machine booted and ready!
==> default: Checking for guest additions in VM...
==> default: Setting hostname...
==> default: Mounting shared folders...
    default: /tk-share => /data/home/jaym/workspace/windows/.kitchen/kitchen-vagrant/default-windows2012r2/share
vagrant up  10.05s user 4.31s system 5% cpu 4:34.39 total
```

* With vagrant-vboxnow (Second run, as first will be slightly slower that before)
```
jaym@angry_dome ~/workspace/vagrant-vboxnow[default]  [master *]
Â± % time bundle exec vagrant up                                                                                                                                                                                                                                           !10212
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'kensykora/windows_2012_r2_standard'...
==> default: Matching MAC address for NAT networking...
==> default: Setting the name of the VM: vagrant-vboxnow_default_1411012306462_88501
==> default: Clearing any previously set network interfaces...
==> default: Preparing network interfaces based on configuration...
    default: Adapter 1: nat
==> default: Forwarding ports...
    default: 3389 => 3389 (adapter 1)
    default: 22 => 2222 (adapter 1)
    default: 5985 => 55985 (adapter 1)
==> default: Running 'pre-boot' VM customizations...
==> default: Booting VM...
==> default: Waiting for machine to boot. This may take a few minutes...
==> default: Machine booted and ready!
==> default: Checking for guest additions in VM...
==> default: Setting hostname...
==> default: Mounting shared folders...
    default: /tk-share => /data/home/jaym/workspace/windows/.kitchen/kitchen-vagrant/default-windows2012r2/share
bundle exec vagrant up  6.50s user 3.14s system 10% cpu 1:35.61 total
```

## Contributing

1. Fork it ( https://github.com/jdmundrawala/vagrant-vboxnow/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
