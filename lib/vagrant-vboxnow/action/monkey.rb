module Vagrant
  module VBoxNow
    module Action
      class MonkeyPatchImportAction

        module Monkey
          def self.included(klass)
            # http://stackoverflow.com/questions/5944278/overriding-method-by-another-defined-in-module
            klass.class_eval do
              remove_method :import
            end
          end

          def import(ovf)
            # Mostly lifted from
            # https://github.com/mitchellh/vagrant/blob/ae1a03903e668aa893956d4ec27f783976854da0/plugins/providers/virtualbox/driver/version_4_3.rb#L163
            ovf = Vagrant::Util::Platform.cygwin_windows_path(ovf)

            output = ""
            total = ""
            last  = 0

            # Dry-run the import to get the suggested name and path
            @logger.debug("Doing dry-run import to determine parallel-safe name...")
            output = execute("import", "-n", ovf)
            result = /Suggested VM name "(.+?)"/.match(output)
            if !result
              raise Vagrant::Errors::VirtualBoxNoName, output: output
            end
            suggested_name = result[1].to_s
            base_name = "vagrant_base_#{suggested_name}"

            # Append millisecond plus a random to the path in case we're
            # importing the same box elsewhere.
            specified_name = "#{suggested_name}_#{(Time.now.to_f * 1000.0).to_i}_#{rand(100000)}"
            @logger.debug("-- Parallel safe name: #{specified_name}")

            # Build the specified name param list
            name_params = [
              "--vsys", "0",
              "--vmname", specified_name,
            ]

            # Extract the disks list and build the disk target params
            disk_params = []
            disks = output.scan(/(\d+): Hard disk image: source image=.+, target path=(.+),/)
            disks.each do |unit_num, path|
              disk_params << "--vsys"
              disk_params << "0"
              disk_params << "--unit"
              disk_params << unit_num
              disk_params << "--disk"
              if Vagrant::Util::Platform.windows?
                # we use the block form of sub here to ensure that if the specified_name happens to end with a number (which is fairly likely) then
                # we won't end up having the character sequence of a \ followed by a number be interpreted as a back reference.  For example, if
                # specified_name were "abc123", then "\\abc123\\".reverse would be "\\321cba\\", and the \3 would be treated as a back reference by the sub
                disk_params << path.reverse.sub("\\#{suggested_name}\\".reverse) { "\\#{specified_name}\\".reverse }.reverse # Replace only last occurrence
              else
                disk_params << path.reverse.sub("/#{suggested_name}/".reverse, "/#{specified_name}/".reverse).reverse # Replace only last occurrence
              end
            end


            @logger.debug('Checking for base snapshot to clone')
            available_vms = execute('list', 'vms')
            result = /"vagrant_base_#{suggested_name}"/.match(available_vms)
            if !result
              # We need to do an import
              base_name_params = [
                "--vsys", "0",
                "--vmname", base_name
              ]
              execute("import", ovf , *base_name_params, *disk_params) do |type, data|
                if type == :stdout
                  # Keep track of the stdout so that we can get the VM name
                  output << data
                elsif type == :stderr
                  # Append the data so we can see the full view
                  total << data.gsub("\r", "")

                  # Break up the lines. We can't get the progress until we see an "OK"
                  lines = total.split("\n")
                  if lines.include?("OK.")
                    # The progress of the import will be in the last line. Do a greedy
                    # regular expression to find what we're looking for.
                    match = /.+(\d{2})%/.match(lines.last)
                    if match
                      current = match[1].to_i
                      if current > last
                        last = current
                        yield current if block_given?
                      end
                    end
                  end
                end
              end
            end

            snapshot_found = false
            begin
              output = execute('snapshot', base_name, 'list')
              snapshot_found = /Name: vagrant_base /.match(output)
            rescue Vagrant::Errors::VBoxManageError
                @logger.debug("failed to list snapshots")
            end

            if !snapshot_found
              # create snapshot
              @logger.debug('Creating snapshot')
              execute('snapshot', base_name, 'take', 'vagrant_base')
            end

            clonevm_opts = [
              '--snapshot', 'vagrant_base',
              '--options', 'link',
              '--name', specified_name,
            ]
            execute('clonevm', base_name, *clonevm_opts, '--register')

            output = execute("list", "vms", retryable: true)
            match = /^"#{Regexp.escape(specified_name)}" \{(.+?)\}$/.match(output)
            return match[1].to_s if match
            nil
          end
        end

        def initialize(app, env)
          @app = app
        end

        def call(env)
          VagrantPlugins::ProviderVirtualBox::Driver::Version_4_3.include(Monkey)
          @app.call(env)
        end
      end
    end
  end
end

