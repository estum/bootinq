# frozen_string_literal: true

require "yaml"
require "singleton"
require "forwardable"
require "bootinq/component"

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
#     default: "-f"
#
#     parts:
#       s: :shared
#
#     mount:
#       a: :api
#       f: :engine
class Bootinq
  include Singleton

  DEFAULT = {
    "env_key" => 'BOOTINQ',
    "default" => '',
    "parts"   => {},
    "mount"   => {}
  }.freeze

  class << self
    protected def delegated(sym) # :no-doc:
      location = caller_locations(1, 1).first
      file, line = location.path, location.lineno
      definiton = %(def self.#{sym}(*args, &block); instance.#{sym}(*args, &block); end)
      class_eval definiton, file, line
    end
  end

  # :call-seq:
  #   Bootinq.require(*groups, verbose: false, &block)
  #
  # The helper method to bootstrap the Bootinq.
  # Sets the BOOTINQ_PATH enviroment variable if it is missing,
  # invokes the <tt>Bootinq.setup</tt> method with the given verbose key argument & block,
  # and, finally, gets Bundler to require the given groups.
  def self.require(*groups, verbose: false, &block) # :yields: Bootinq.instance
    ENV['BOOTINQ_PATH'] ||= File.expand_path('../bootinq.yml', caller_locations(1..1)[0].path)

    setup(verbose: verbose, &block)

    Bundler.require(*instance.groups(*groups))
  end

  # :call-seq:
  #   Bootinq.setup(verbose: false, &block) -> true or false
  #
  # Initializes itself. To track inquired components use <tt>verbose: true</tt> key argument.
  # Optionally yields block within the own instance's binding.
  def self.setup(verbose: false, &block) # :yields: Bootinq.instance
    instance
    puts "Bootinq: loading components #{instance.components.join(', ')}" if verbose
    instance.instance_exec(&block) if block_given?
    instance
  end

  attr_reader :flags
  attr_reader :components

  delegated :flags
  delegated :components

  def initialize # :no-doc:
    config_path = ENV.fetch('BOOTINQ_PATH')
    config = YAML.safe_load(File.read(config_path), [Symbol])
    config.merge!(DEFAULT) { |_, l, r| l.nil? ? r : l }

    @_value     = ENV.fetch(config['env_key']) { config['default'] }
    @_neg       = @_value.start_with?(?-, ?^)
    @flags      = []
    @components = []

    config['parts'].each { |flag, name| enable_component(name, flag: flag) }
    config['mount'].each { |flag, name| enable_component(name, flag: flag, as: Mountable) }
  end

  # :call-seq:
  #   Bootinq.enable_component(name, flag: [, as: Component])
  #
  delegated def enable_component(name, flag:, as: Component)
    if @_neg ^ @_value.include?(flag)
      @flags      << flag
      @components << as.new(name)
    end
  end

  # :call-seq:
  #   Bootinq.enabled?(name) -> true or false
  #
  # Checks if a component with the given name (i.e. the same gem group)
  # is enabled
  delegated def enabled?(name)
    components.include?(name)
  end

  # :call-seq:
  #   Bootinq.component(name) -> Bootinq::Component
  #   Bootinq[name] -> Bootinq::Component
  #
  # Returns a <tt>Bootinq::Component</tt> object by its name
  delegated def component(name)
    components[components.index(name)]
  end

  alias :[] :component
  delegated :[]

  # :call-seq:
  #   Bootinq.each_mountable { |part| block } -> Array
  #   Bootinq.each_mountable -> Enumerator
  #
  # Calls the given block once for each enabled mountable component
  # passing that part as a parameter. Returns the array of all mountable components.
  #
  # If no block is given, an Enumerator is returned.
  delegated def each_mountable(&block) # :yields: part
    components.select(&:mountable?).each(&block)
  end

  # :call-seq:
  #   Bootinq.groups(*groups)
  #
  # Merges enabled Bootinq's groups with the given groups and, if loaded with Rails,
  # passes them to <tt>Rails.groups</tt> method, otherwise just returns the merged list
  # to use with <tt>Bundler.require</tt>.
  delegated def groups(*groups)
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
  delegated def on(name = nil, any: nil, all: nil) # :yields:
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
  delegated def on_all(*parts) # :yields:
    is_matched = parts.all? { |p| enabled?(p) }
    yield if is_matched && block_given?
    is_matched
  end

  # :call-seq:
  #   Bootinq.on_all(*names) { block } -> true or false
  #
  # Takes a list of component names and yields a given block  (optionally)
  # if any of them are enabled. Returns boolean matching status.
  delegated def on_any(*parts) # :yields:
    is_matched = parts.any? { |p| enabled?(p) }
    yield if is_matched && block_given?
    is_matched
  end

  # Freezes every instance variables and the instance itself.
  def freeze
    @_value.freeze
    @_neg.freeze
    @flags.freeze
    @components.freeze
    super
  end

  def self.new
    super.freeze
  end

  private_class_method :new
end