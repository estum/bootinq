# frozen_string_literal: true

class Bootinq
  # When just required, hooks {Bootinq#enable_component} method to
  # generate fast inline wrapping methods.
  #
  # @see Mixins#enable_component
  #
  # @example Usage
  #   require 'bootinq'
  #   require 'bootinq/mixins'
  module Mixins
    # @api private
    module ComputeNameMethod
      DASH = '_'

      private_constant :DASH

      def compute_name(component_name)
        component_name.to_s.split(DASH).
          each(&:capitalize!).
          join << @name_suffix
      end
    end

    private_constant :ComputeNameMethod

    # @api private
    class Enabled < ::Module
      @name_suffix = 'EnabledMixin'
      extend ComputeNameMethod

      def initialize(module_name, component_name)
        module_eval <<~RUBY, __FILE__, __LINE__ + 1
        # Yields the block due to component is enabled
        # @yield [void]
        def on_#{component_name}(*)
          yield
        end

        # Does nothing due to component is enabled
        # @return [void]
        def not_#{component_name}(*)
        end
        RUBY
      end
    end

    private_constant :Enabled

    # @api private
    class Disabled < ::Module
      @name_suffix = 'DisabledMixin'
      extend ComputeNameMethod

      def initialize(module_name, component_name)
        define_method(:name, module_name.method(:itself))

        module_eval <<~RUBY, __FILE__, __LINE__ + 1
        # Does nothing due to component is disabled
        # @return [void]
        def on_#{component_name}(*)
        end

        # Yields the block due to component is disabled
        # @yield [void]
        def not_#{component_name}(*)
          yield
        end
        RUBY
      end
    end

    private_constant :Disabled

    Builder = -> (component_name, enabled) do
      klass = enabled ? Enabled : Disabled
      module_name = klass.compute_name(component_name).freeze

      if Bootinq.const_defined?(module_name)
        Bootinq.const_get(module_name)
      else
        Bootinq.const_set(module_name, klass.new(module_name, component_name))
      end
    end

    private_constant :Builder

    # Generates {Enabled} or {Disabled} mixin and sets it to a constant once,
    # bypassing if it has been already defined.
    # @yield [component_name, enabled]
    # @return [void]
    def enable_component(name, **opts)
      super(name, **opts) do |component_name, enabled|
        Bootinq.extend Builder[component_name, enabled]
        yield(component_name, enabled) if block_given?
      end
    end
  end

  prepend Mixins
end
