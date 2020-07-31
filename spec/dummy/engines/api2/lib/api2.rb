require "rails/engine"

module Api2
  class Engine < ::Rails::Engine
    isolate_namespace Api2
  end
end