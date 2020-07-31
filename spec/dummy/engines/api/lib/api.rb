require "rails/engine"

module Api
  class Engine < ::Rails::Engine
    isolate_namespace Api
  end
end