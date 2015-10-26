require "yaml"
require "erb"
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
  NEG     = '-'.freeze
  DEFAULT = {
    "env_key" => 'BOOTINQ',
    "default" => '',
    "parts"   => {},
    "mount"   => {}
  }

  attr_reader :flags, :components

  include Singleton
  extend SingleForwardable

  def initialize
    config = YAML.load(File.read(ENV['BOOTINQ_PATH']))
    config.reject! { |_, v| v.nil? }
    config.reverse_merge!(DEFAULT)

    config['parts'].merge!(config['mount'])

    value = ENV[config['env_key']] || config['default'].to_s
    neg   = value.start_with?(NEG)

    flags = []
    parts = []

    config['parts'].each do |flag, name|
      if neg ^ value[flag]
        flags << flag
        parts << Component.new(name, mountable: config['mount'].key?(flag))
      end
    end

    @_value     = value.freeze
    @_neg       = neg.freeze
    @flags      = flags.freeze
    @components = parts.freeze
  end

  # Checks if a given gem (i.e. a gem group) is enabled
  def enabled?(gem_name)
    components.include?(gem_name)
  end

  # Returns a <tt>Bootinq::Component</tt> object by its name
  def component(key)
    components[components.index(key)]
  end

  # Enums each mountable component
  def each_mountable
    return to_enum(__method__) unless block_given?
    components.each { |c| yield(c) if c.mountable? }
  end

  # Invokes <tt>Rails.groups</tt> method within enabled Bootinq's groups
  def groups(*list)
    Rails.groups(*components.map(&:group), *list)
  end

  # Yields the given block if any of given components is enabled.
  #
  # ==== Example:
  #
  #   Bootinq.on :frontend do
  #     # make frontend thing...
  #   end
  def on(*names) # :yields:
    if names.any? { |name| enabled?(name) }
      yield
    end
  end

  def_delegators "instance", *instance_methods(false)

  class << self
    # The helper method to bootstrap the Bootinq.
    # Sets the BOOTINQ_PATH enviroment variable, yields optional block in
    # the own instance's binding and, finally, requires selected bundler groups.
    def require(*groups, &block) # :yields:
      ENV['BOOTINQ_PATH'] ||= File.expand_path('../bootinq.yml', caller_locations(1..1)[0].path)
      instance.instance_exec(&block) if block_given?
      Bundler.require(*instance.groups(*groups))
    end

    private def new
      super.freeze
    end
  end
end