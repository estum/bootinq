# frozen_string_literal: true

require 'rails'

class Bootinq
  # Require `bootinq/railtie` in the `before_configuration` block of your
  # application definition to allow load component-scoped config paths
  # only when the named component is enabled:
  #
  #   - `config/routes.rb` → `config/routes.component.rb`
  #   - `config/locales` → `config/locales.component`
  #   - `config/initializers` → `config/initializers.component`
  #
  # It doesn't affect on the default paths without suffix.
  #
  # @example
  #   # config/application.rb
  #   module Example
  #     class Application < Rails::Application
  #       config.before_configuration do
  #         require 'bootinq/railtie'
  #       end
  #     end
  #   end
  class Railtie < ::Rails::Railtie
    initializer 'bootinq.add_locales', before: :add_locales do |app|
      Bootinq.components.each do |component|
        app.paths["config/locales"] << "config/locales.#{component.name}"
      end
    end

    initializer 'bootinq.load_config_initializers', before: :load_config_initializers do |app|
      Bootinq.components.each do |component|
        app.paths["config/initializers"] << "config/initializers.#{component.name}"
      end
    end

    initializer 'bootinq.add_routing_paths', before: :add_routing_paths do |app|
      Bootinq.components.each do |component|
        app.paths["config/routes.rb"] << "config/routes.#{component.name}.rb"
      end
    end
  end
end
