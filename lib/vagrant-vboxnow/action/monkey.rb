module Vagrant
  module VBoxNow
    module Action
      class MonkeyPatchImportAction
        def initialize(app, env)
          @app = app
        end

        def call(env)
          raise 'Im here'
        end
      end
    end
  end
end

