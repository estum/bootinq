# frozen_string_literal: true

require 'rails'

class Bootinq
  # @return [Bootinq::RailsPath]
  def self.rails_path
    @@rails_path ||= RailsPath.new
  end

  # @param path [String] original path
  # @return [Array<String>] list of pathes for each components
  def self.component_paths_for(path)
    components.map(&rails_path[path])
  end

  # @param paths_path [Rails::Paths::Path]
  # @return [void]
  def self.add_component_paths_to(paths_path)
    raise ArgumentError unless paths_path.is_a?(Rails::Paths::Path)
    original = paths_path.instance_variable_get(:@paths)[0]
    component_paths = component_paths_for(original)
    paths_path.concat(component_paths)
  end

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
  # It's also possible to use subdirs instead of suffix, see the example.
  #
  # @example Setup
  #   # config/application.rb
  #   module Example
  #     class Application < Rails::Application
  #       config.before_configuration do
  #         require 'bootinq/railtie'
  #         # To use subdir path template instead of suffix:
  #         # Bootinq.rails_path.template = Bootinq::RailsPath::TEMPLATES[:subdir]
  #       end
  #     end
  #   end
  class Railtie < ::Rails::Railtie
    initializer 'bootinq.add_locales', before: :add_locales do |app|
      Bootinq.add_component_paths_to app.paths["config/locales"]
    end

    initializer 'bootinq.load_config_initializers', before: :load_config_initializers do |app|
      Bootinq.add_component_paths_to app.paths["config/initializers"]
    end

    initializer 'bootinq.add_routing_paths', before: :add_routing_paths do |app|
      Bootinq.add_component_paths_to app.paths["config/routes.rb"]
    end
  end
end
