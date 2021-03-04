# frozen_string_literal: true

require "yaml"
require "singleton"
require "forwardable"
require "bootinq/component"
require "bootinq/switch"

# = Bootinq
#
# == Installation
#
# === Ruby on Rails
#
# 1. Insert <tt>require "bootinq"</tt> in the top of <tt>config/application.rb</tt>
#
# 2. Find <tt>Bundler.require(*Rails.groups)</tt> line below and replace it
#    with the <tt>Bootinq.require</tt>.
#
# === Other
#
# 1. Locate <tt>Bundler.require(...)</tt> in your app and insert <tt>require "bootinq"</tt> above.
#
# 2. Replace located <tt>Bundler.require(...)</tt> line with the <tt>Bootinq.require(...)</tt>.
#
# For example, if you are using Grape:
#
#     # config/application.rb
#
#     require 'boot'
#     require 'bootinq'
#
#     # Bundler.require :default, ENV['RACK_ENV']
#     Bootinq.require :default, ENV['RACK_ENV'], verbose: true
#     ...
#
# == Example <tt>config/bootinq.yml</tt>:
#
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
#
class Bootinq
  include Singleton

  DEFAULT = {
    "env_key" => 'BOOTINQ',
    "default" => '',
    "parts"   => {},
    "mount"   => {},
    "deps"    => {}
  }.freeze

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

  # :call-seq:
  #   Bootinq.require(*groups, verbose: false, &block)
  #
  # Invokes the <tt>Bootinq.init</tt> method with the given verbose key argument & block,
  # and, finally, makes Bundler to require the given groups.
  def self.require(*groups, verbose: false, &block) # :yields: Bootinq.instance
    init(verbose: verbose, &block)
    Bundler.require(*instance.groups(*groups))
  end

  # :call-seq:
  #   Bootinq.setup(*groups, verbose: false, &block)
  #
  # Invokes the <tt>Bootinq.init</tt> method with the given verbose key argument & block,
  # and, finally, makes Bundler to setup the given groups.
  def self.setup(*groups, verbose: false, &block) # :yields: Bootinq.instance
    init(verbose: verbose, &block)
    Bundler.setup(*instance.groups(*groups))
  end

  # :call-seq:
  #   Bootinq.init(verbose: false, &block) -> true or false
  #
  # Initializes itself. Sets the BOOTINQ_PATH enviroment variable if it is missing.
  # To track inquired components use <tt>verbose: true</tt> key argument.
  # Optionally yields block within the own instance's binding.
  def self.init(verbose: false, &block) # :yields: Bootinq.instance
    ENV['BOOTINQ_PATH'] ||= File.expand_path('../bootinq.yml', caller_locations(2, 1)[0].path)

    instance
    instance.instance_variable_set(:@_on_ready, block.to_proc) if block_given?
    puts "Bootinq: loading components #{instance.components.join(', ')}" if verbose
    instance.ready!
  end

  # Reads config from the given or default path, deserializes it and returns as a hash.
  def self.deserialized_config(path: nil)
    bootinq_yaml = File.read(path || ENV.fetch('BOOTINQ_PATH'))
    YAML.safe_load(bootinq_yaml, [Symbol])
  end

  attr_reader :flags
  attr_reader :components

  def initialize # :no-doc:
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

  def ready? # :no-doc:
    !!@ready
  end

  # :call-seq:
  #   Bootinq.ready! -> nil or self
  #
  # At the first call marks Bootinq as ready and returns the instance,
  # otherwise returns nil.
  def ready!
    return if ready?
    @ready = true
    if defined?(@_on_ready)
      instance_exec(&@_on_ready)
      remove_instance_variable :@_on_ready
    end
    freeze
  end

  # :call-seq:
  #   Bootinq.enable_component(name, flag: [, as: Component])
  #
  def enable_component(name, flag:, as: Component)
    if is_dependency?(name) || @_value.include?(flag)
      @flags      << flag
      @components << as.new(name)
    end
  end

  # :call-seq:
  #   Bootinq.enabled?(name) -> true or false
  #
  # Checks if a component with the given name (i.e. the same gem group)
  # is enabled
  def enabled?(name)
    components.include?(name)
  end

  # :call-seq:
  #   Bootinq.component(name) -> Bootinq::Component
  #   Bootinq[name] -> Bootinq::Component
  #
  # Returns a <tt>Bootinq::Component</tt> object by its name
  def component(name)
    components[components.index(name)]
  end

  alias :[] :component

  # :call-seq:
  #   Bootinq.each_mountable { |part| block } -> Array
  #   Bootinq.each_mountable -> Enumerator
  #
  # Calls the given block once for each enabled mountable component
  # passing that part as a parameter. Returns the array of all mountable components.
  #
  # If no block is given, an Enumerator is returned.
  def each_mountable(&block) # :yields: part
    components.select(&:mountable?).each(&block)
  end

  # :call-seq:
  #   Bootinq.groups(*groups)
  #
  # Merges enabled Bootinq's groups with the given groups and, if loaded with Rails,
  # passes them to <tt>Rails.groups</tt> method, otherwise just returns the merged list
  # to use with <tt>Bundler.require</tt>.
  def groups(*groups)
    groups.unshift(*components.map(&:group))
    if defined?(Rails)
      Rails.groups(*groups)
    else
      groups
    end
  end

  # :call-seq:
  #   Bootinq.on(name) { block } -> true or false
  #   Bootinq.on(any: [names]) { block } -> true or false
  #   Bootinq.on(all: [names]) { block } -> true or false
  #
  # Takes a component's name or single-key options hash as an argument and
  # yields a given block if the target components are enabled.
  #
  # See examples for a usage.
  #
  # ==== Example:
  #
  #   Bootinq.on :frontend do
  #     # make frontend thing...
  #   end
  #
  #   Bootinq.on any: %i(frontend backend) do
  #     # do something when frontend or backend is enabled
  #   end
  #
  #   Bootinq.on all: %i(frontend backend) do
  #     # do something when frontend and backend are enabled
  #   end
  def on(name = nil, any: nil, all: nil) # :yields:
    if name.nil? && any.nil? && all.nil?
      raise ArgumentError, "wrong arguments (given 0, expected 1)"
    elsif (any && all) || (name && (any || all))
      raise ArgumentError, "expected single argument or one of keywords: `all' or `any'"
    end

    is_matched =
      name ? enabled?(name) :
      any  ? on_any(*any) :
      all  ? on_all(*all) : false
    yield if is_matched
    is_matched
  end

  # :call-seq:
  #   Bootinq.on_all(*names) { block } -> true or false
  #
  # Takes a list of component names and yields a given block (optionally)
  # if all of them are enabled. Returns boolean matching status.
  def on_all(*parts) # :yields:
    is_matched = parts.all? { |p| enabled?(p) }
    yield if is_matched && block_given?
    is_matched
  end

  # :call-seq:
  #   Bootinq.on_all(*names) { block } -> true or false
  #
  # Takes a list of component names and yields a given block  (optionally)
  # if any of them are enabled. Returns boolean matching status.
  def on_any(*parts) # :yields:
    is_matched = parts.any? { |p| enabled?(p) }
    yield if is_matched && block_given?
    is_matched
  end

  # :call-seq:
  #   Bootinq.switch(*parts) { block } -> nil
  #
  # Collector method.
  #
  # Example:
  #
  #   Bootinq.switch do |part|
  #     part.frontend { … }
  #     part.backend { … }
  #   end
  def switch # :yields: Bootinq::Switch.new
    yield(Switch.new)
    nil
  end

  # :call-seq:
  #   is_dependency?(part_name) -> true or false
  #
  # Checks if the named component is a dependency of the enabled one.
  def is_dependency?(name)
    @_deps.key?(name) && @_value.count(@_deps[name]['in'].to_s) > 0
  end

  # Freezes every instance variables and the instance itself.
  def freeze
    @_value.freeze
    @_neg
    @flags.freeze
    @components.freeze
    super
  end

  delegate_template = <<~RUBY
    def self.%1$s(*args, &block)
      instance.%1$s(*args, &block)
    end
  RUBY

  %I(flags
     components
     ready?
     ready!
     enable_component
     enabled?
     component
     []
     each_mountable
     groups
     on
     on_all
     on_any
     switch
  ).each { |sym| class_eval(delegate_template  % sym, *instance_method(sym).source_location) }
end