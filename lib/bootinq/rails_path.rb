# frozen_string_literal: true

class Bootinq
  # Callable component-scoped path generator. Global-accessible instance is in {Bootinq.rails_path}
  #
  # @example Customize template
  #   Bootinq.rails_path.template = "%<base>.%<component>%<ext>" # (default template)
  #   Bootinq.rails_path.template = "%<base>.%<component>%<ext>" # (default template)
  #
  #   Bootinq.rails_path["app/controllers", :admin] # => "app/controllers.admin"
  #   Bootinq.rails_path["config/routes.rb", :admin] # => "config/routes.admin.rb"
  #
  class RailsPath
    TEMPLATES = {
      default: "%<base>s.%<component>s%<ext>s",
      subdir:  "%<base>s/%<component>s%<ext>s"
    }

    # @!attribute template [rw]
    #   @return [String]
    #     Format string using named references `base`, `component` and `ext`.
    attr_accessor :template

    # @param template [String] (TEMPLATES[:default])
    #   path template
    # @return [self]
    def initialize(template = TEMPLATES[:default])
      @template = template
    end

    # @overload call(path, component)
    #   Generates rails config path for the given component by using {Bootinq.rails_config_path_template}.
    #   @param path [String] original path
    #   @param component [String] component name
    #   @return [String] component-scoped path
    #
    # @overload call(path)
    #   Prepares a curried proc for a path. Generally desinged to use within enumerators.
    #   @param path [String] original path
    #   @return [Proc]
    #   @example Usage
    #     # components: api, internal, admin
    #     Bootinq.components.map(&Bootinq.rails_path['config/routes.rb'])
    #     # => ['config/routes.api.rb', 'config/routes.internal.rb', 'config/routes.admin.rb']
    def call(path, component = nil)
      ext = File.extname(path)
      base = path.delete_suffix(ext)
      ref = { base: base, ext: ext }
      if component.nil?
        -> (component) { apply(**ref, component: component) }
      else
        apply(**ref, component: component)
      end
    end

    alias_method :[], :call

    private

    # @api private
    def apply(**ref)
      @template % ref
    end
  end
end
