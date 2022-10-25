# frozen_string_literal: true

require "yaml"
require "singleton"
require "forwardable"
require "bootinq/component"
require "bootinq/switch"

# # Bootinq
#
# ## Installation
#
# ### Ruby on Rails
#
#   1. insert `require "bootinq"` on top of `config/application.rb`;
#   2. find and replace `Bundler.require(*Rails.groups)` with `Bootinq.require`
#
# ### Other frameworks
#
#   1. locate `Bundler.require(…)` in your app and insert `require "bootinq"` above it;
#   2. replace previosly located `Bundler.require(…)` line with the `Bootinq.require(…)`.
#
# @example Grape
#     # config/application.rb
#
#     require 'boot'
#     require 'bootinq'
#
#     # Bundler.require :default, ENV['RACK_ENV']
#     Bootinq.require :default, ENV['RACK_ENV'], verbose: true
#
# @example config/bootinq.yml
#     env_key: BOOTINQ
#     default: a
#
#     parts:
#       s: :shared
#
#     mount:
#       a: :api
#       f: :engine
#
#     deps:
#       shared:
#         in: af
class Bootinq
  include Singleton

  DEFAULT = {
    "env_key" => 'BOOTINQ',
    "default" => '',
    "parts"   => {},
    "mount"   => {},
    "deps"    => {}
  }.freeze

  ALL = %i[* all].freeze

  FilterNegValue = -> (value, config) do
    if value.start_with?(?-, ?^)
      value = value.tr('\\-', '\\^')
      flags = (config['parts'].keys + config['mount'].keys).join
      [true, flags.delete(flags.delete(value))]
    else
      [false, value.dup]
    end
  end

  private_constant :FilterNegValue

  # Invokes the {init} method with the given options and block,
  # then calls {Bundler.require} with the enabled groups.
  # @see init
  # @see Bundler.require
  # @param groups [Array<Symbol>]
  # @param options [Hash]
  #   initialization options
  # @option options [Boolean] verbose
  #   track inquired components
  # @option options [Proc] on_ready
  #   optional ready callback proc
  # @return [void]
  def self.require(*groups, **options, &on_ready)
    init(**options, &on_ready)
    Bundler.require(*instance.groups(*groups))
  end

  # Invokes the {init} method with the given options and block,
  # then calls {Bundler.require} with the enabled groups.
  # @see init
  # @see Bundler.setup
  # @param groups [Array<Symbol>]
  # @param options [Hash]
  #   initialization options
  # @option options [Boolean] verbose
  #   track inquired components
  # @option options [Proc] on_ready
  #   optional ready callback proc
  # @yield [instance]
  # @return [void]
  def self.setup(*groups, **options, &on_ready) # :yields: Bootinq.instance
    init(**options, &on_ready)
    Bundler.setup(*instance.groups(*groups))
  end

  # Sets `BOOTINQ_PATH` enviroment variable if it is missing & initializes itself
  # @overload init(verbose: false, on_ready:)
  # @overload init(verbose: false, &on_ready)
  # @param verbose [Boolean]
  #   track inquired components
  # @param on_ready [Proc]
  #   optional ready callback proc
  # @return [instance]
  def self.init(verbose: false, on_ready: nil, &block)
    ENV['BOOTINQ_PATH'] ||= File.expand_path('../bootinq.yml', caller_locations(2, 1)[0].path)

    instance
    on_ready = block.to_proc if on_ready.nil? && block_given?
    instance.instance_variable_set(:@_on_ready, on_ready.to_proc) if on_ready

    puts "Bootinq: loading components #{instance.components.join(', ')}" if verbose

    instance.ready!
  end

  # Reads config
  # @param path [String]
  #   path to yaml config (default: ENV['BOOTINQ_PATH'])
  # @return [Hash]
  #   deserializes yaml config
  def self.deserialized_config(path: nil)
    bootinq_yaml = File.read(path || ENV.fetch('BOOTINQ_PATH'))
    psych_safe_load(bootinq_yaml, [Symbol])
  end

  # @api private
  if RUBY_VERSION >= '3.1.0'
    def self.psych_safe_load(path, permitted_classes)
      YAML.safe_load(path, permitted_classes: permitted_classes)
    end
  else
    def self.psych_safe_load(*args)
      YAML.safe_load(*args)
    end
  end

  private_class_method :psych_safe_load

  # @!attribute flags [r]
  #   @return [Array<String>]

  attr_reader :flags

  # @!attribute components [r]
  #   @return [Array<String>]

  attr_reader :components

  # @return [self]
  def initialize
    config = self.class.deserialized_config
    config.merge!(DEFAULT) { |_, l, r| l.nil? ? r : l }

    @_orig_value = ENV.fetch(config['env_key']) { config['default'] }
    @_neg, @_value = FilterNegValue[@_orig_value, config]

    @_deps = config['deps']

    @flags      = []
    @components = []

    config['parts'].each { |flag, name| enable_component(name, flag: flag.to_s) }
    config['mount'].each { |flag, name| enable_component(name, flag: flag.to_s, as: Mountable) }
  end

  # @return [Boolean]
  def ready?
    !!@ready
  end

  # Once-only set {Bootinq} to ready state firing the `@_on_ready` callback.
  # @return [self] on the first call
  # @return [void] after
  def ready!
    return if ready?
    @ready = true
    if defined?(@_on_ready)
      Bootinq.class_exec(&@_on_ready)
      remove_instance_variable :@_on_ready
    end
    freeze
  end

  # Enables the given component if it is required by flag or
  # when another enabled component depends it.
  # @param name [String]
  #   of the component
  # @param flag [String]
  #   the component's assigned char flag
  # @param as [Class]
  #   the component's constructor class
  # @yield [name, is_enabled]
  # @return [void]
  def enable_component(name, flag:, as: Component)
    if is_dependency?(name) || @_value.include?(flag)
      @flags      << flag
      @components << as.new(name)
      yield(name, true) if block_given?
    else
      yield(name, false) if block_given?
    end

    nil
  end

  # Checks if a component with the given name (i.e. the same gem group)  is enabled
  # @return [Boolean]
  def enabled?(name)
    ALL.include?(name) || @components.include?(name)
  end

  # @param name [String, Symbol]
  # @return [Bootinq::Component]
  def component(name)
    @components[@components.index(name)]
  end

  alias_method :[], :component

  # Checks if a component with the given name (i.e. the same gem group)  is disabled
  # @return [Boolean]
  def disabled?(name)
    !@components.include?(name)
  end

  # Enumerates enabled mountable components
  # @overload each_mountable()
  # @overload each_mountable(&block)
  #   @yield [component]
  # @return [Enumerator]
  def each_mountable
    return enum_for(:each_mountable) unless block_given?

    @components.each do |component|
      yield(component) if component.mountable?
    end
  end

  # Merges groups of enabled components with the given ones.
  # When loaded with Rails, it passes them to {Rails.groups} method,
  # otherwise just returns the merged list to use it with {Bundler.require}.
  # @param groups [Array<String, Symbol>]
  # @return [Array<String, Symbol>] merged groups
  def groups(*groups)
    @components.each do |component|
      next if groups.include?(component.group)
      groups.unshift(component.group)
    end

    defined?(Rails) ? Rails.groups(*groups) : groups
  end

  # @overload on(name)
  #   @yield [void] (if component is enabled)
  #   @param name [Symbol] single component's name
  #
  # @overload on(any:)
  #   @see on_any
  #   @yield [void] (if _any_ matching component is enabled)
  #   @param any [Array<Symbol>] list of components' names
  #
  # @overload on(all:)
  #   @see on_all
  #   @yield [void] (if _all_ matching components are enabled)
  #   @param all [Array<Symbol>] list of components' names
  #
  # @return [Boolean] matching status
  #
  # @example single
  #   Bootinq.on(:frontend) { puts 'frontend' }
  # @example any
  #   Bootinq.on(any: %i[frontend backend]) { puts 'frontend or backend' }
  # @example all
  #   Bootinq.on(all: %i[frontend backend]) { puts 'both' }
  def on(name = nil, any: nil, all: nil)
    if name && ALL.include?(name)
      yield
      return true
    end

    is_matched =
      name ? enabled?(name) :
      any  ? on_any(*any) :
      all  ? on_all(*all) : false

    yield if is_matched

    is_matched
  end

  # @yield [void]
  #   if _all_ matching components are enabled
  # @param parts [Array<String, Symbol>]
  #   list of components' names
  # @return [Boolean]
  #   matching status
  def on_all(*parts) # :yields:
    is_matched = parts.reduce(true) { |m, part| m && enabled?(part) }
    yield if is_matched && block_given?
    is_matched
  end

  # @yield [void]
  #   if _any_ matching component is enabled
  # @param parts [Array<String, Symbol>]
  #   list of components' names
  # @return [Boolean]
  #   matching status
  def on_any(*parts) # :yields:
    is_matched = parts.reduce(false) { |m, part| m || enabled?(part) }
    yield if is_matched && block_given?
    is_matched
  end

  # @overload not(name)
  #   @yield [void] (if component is disabled)
  #   @param name [Symbol] single component's name
  #
  # @overload not(any:)
  #   @see not_any
  #   @yield [void] (if _any_ matching component is disabled)
  #   @param any [Array<Symbol>] list of components' names
  #
  # @overload not(all:)
  #   @see not_all
  #   @yield [void] (if _all_ matching components are disabled)
  #   @param all [Array<Symbol>] list of components' names
  #
  # @return [Boolean] matching status
  #
  # @example single
  #   Bootinq.not(:frontend) { puts 'not frontend' }
  # @example any
  #   Bootinq.not(any: %i[frontend backend]) { puts 'neither frontend nor backend' }
  # @example all
  #   Bootinq.on(all: %i[frontend backend]) { puts 'both disabled' }
  def not(name = nil, any: nil, all: nil)
    is_matched =
      name ? disabled?(name) :
      any  ? not_any(*any) :
      all  ? not_all(*all) : false

    yield if is_matched

    is_matched
  end

  # @yield [void]
  #   if _all_ matching components are disabled
  # @param parts [Array<String, Symbol>]
  #   list of components' names
  # @return [Boolean]
  #   matching status
  def not_all(*parts) # :yields:
    is_matched = parts.reduce(true) { |m, part| m && disabled?(part) }
    yield if is_matched && block_given?
    is_matched
  end

  # @yield [void]
  #   if _any_ matching component is disabled
  # @param parts [Array<String, Symbol>]
  #   list of components' names
  # @return [Boolean]
  #   matching status
  def not_any(*parts) # :yields:
    is_matched = parts.reduce(false) { |m, part| m || disabled?(part) }
    yield if is_matched && block_given?
    is_matched
  end

  # Collector method.
  # @example
  #   Bootinq.switch do |part|
  #     part.frontend { … }
  #     part.backend { … }
  #   end
  # @yield [switch]
  # @see Bootinq::Switch
  # @return [void]
  def switch
    yield(Switch.new)
    nil
  end

  # Checks if the named component is dependent by another enabled one.
  # @param name [String, Symbol]
  # @return [Boolean]
  def is_dependency?(name)
    @_deps.key?(name.to_s) &&
    @_value.count(@_deps.dig(name.to_s, 'in').to_s) > 0
  end

  # @api private
  def freeze
    @_value.freeze
    @_neg
    @flags.freeze
    @components.freeze
    super
  end

  extend SingleForwardable

  def_delegator :instance, :component
  def_delegator :instance, :components
  def_delegator :instance, :each_mountable
  def_delegator :instance, :enabled?
  def_delegator :instance, :enable_component
  def_delegator :instance, :disabled?
  def_delegator :instance, :flags
  def_delegator :instance, :groups
  def_delegator :instance, :on
  def_delegator :instance, :on_all
  def_delegator :instance, :on_any
  def_delegator :instance, :not
  def_delegator :instance, :not_all
  def_delegator :instance, :not_any
  def_delegator :instance, :ready!
  def_delegator :instance, :ready?
  def_delegator :instance, :switch
  def_delegator :instance, :[]
end