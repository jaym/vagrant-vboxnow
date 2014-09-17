require 'pry'
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
            raise 'Now here'
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

