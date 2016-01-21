require "yaml"
require "singleton"
require "forwardable"
require "bootinq/component"

# = Bootinq
#
# == Installation
#
# 1. Insert <tt>require "bootinq"</tt> in the top of <tt>config/application.rb</tt>
#
# 2. Find <tt>Bundler.require(*Rails.groups)</tt> line below and replace it
#    with the <tt>Bootinq.require</tt>.
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
  extend SingleForwardable
  include Singleton

  NEG_OPS = %w(- ^).freeze
  DEFAULT = {
    "env_key" => 'BOOTINQ',
    "default" => '',
    "parts"   => {},
    "mount"   => {}
  }.freeze

  # The helper method to bootstrap the Bootinq.
  # Sets the BOOTINQ_PATH enviroment variable, yields optional block in
  # the own instance's binding and, finally, requires selected bundler groups.
  def self.require(*groups, logger: nil, &block) # :yields:
    ENV['BOOTINQ_PATH'] ||= File.expand_path('../bootinq.yml', caller_locations(1..1)[0].path)

    logger.debug { "Bootinq: loading components #{instance.components.join(', ')}" } if logger.respond_to?(:debug)

    instance.instance_exec(&block) if block_given?

    Bundler.require(*instance.groups(*groups))
  end

  private_class_method def self.new # :nodoc:
    super.freeze
  end


  attr_reader :flags, :components

  def initialize
    config = YAML.safe_load(File.read(ENV.fetch('BOOTINQ_PATH')), [Symbol]).
      merge!(DEFAULT) { |_,l,r| l.nil? ? r : l }

    @_value     = ENV.fetch(config['env_key']) { config['default'] }
    @_neg       = @_value.start_with?(*NEG_OPS)
    @flags      = []
    @components = []

    config['parts'].each { |flag, name| enable_component(flag) { Component.new(name) } }
    config['mount'].each { |flag, name| enable_component(flag) { Mountable.new(name) } }
  end

  # Checks if a given gem (i.e. a gem group) is enabled
  def enabled?(gem_name)
    components.include?(gem_name)
  end

  # Returns a <tt>Bootinq::Component</tt> object by its name
  def component(key)
    components[components.index(key)]
  end

  alias :[] :component

  # Enums each mountable component
  def each_mountable
    return to_enum(__method__) unless block_given?
    components.each { |part| yield(part) if part.mountable? }
  end

  # Invokes <tt>Rails.groups</tt> method within enabled Bootinq's groups
  def groups(*list)
    Rails.groups(*components.map(&:group), *list)
  end

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
  def on(name) # :yields:
    if name.is_a?(Hash)
      %i(any all).each do |m|
        list = name[m]
        next unless list.is_a?(Enumerable)
        yield if list.public_send(:"#{m}?") { |part| enabled?(part) }
      end
    else
      yield if enabled?(name)
    end
  end

  def freeze # :no-doc:
    @_value.freeze
    @_neg.freeze
    @flags.freeze
    @components.freeze
    super
  end

  def_delegators "instance", *instance_methods(false)

  private def enable_component(flag) # :yields:
    if @_neg ^ @_value.include?(flag)
      @flags      << flag
      @components << yield
    end
  end
end