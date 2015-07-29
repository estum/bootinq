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
#     :env_key: "BOOTINQ"
#     :default_flags: "-f"
#     :components:
#       s:
#         - :shared
#       a:
#         - :api
#         - :mountable: true
#       f:
#         - :frontend
#         - :mountable: true
class Bootinq
  NEGATIVE_SYMBOL = '-'.freeze

  DEFAULT_CONFIG = {
    :env_key       => 'BOOTINQ',
    :default_flags => '',
    :components    => {}
  }

  attr_reader :flags, :components

  include Singleton
  extend SingleForwardable

  def initialize
    config = YAML.load(File.read(ENV['BOOTINQ_PATH']))
    config.reverse_merge! DEFAULT_CONFIG

    value = ENV[config[:env_key]]
    value = config[:default_flags] if value.nil? || value.blank?
    neg   = value.start_with?(NEGATIVE_SYMBOL)

    flags = config[:components].keys
    flags.select! { |flag| neg ^ value[flag] }

    components = config[:components].values_at(*flags)
    components.map! { |args| Component.new(*args) }

    @_value     = value.freeze
    @_neg       = neg.freeze
    @flags      = flags.freeze
    @components = components.freeze
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
  def groups(*groups)
    Rails.groups(*components.map(&:group), *groups)
  end

  def_delegators "instance", *instance_methods(false)

  class << self
    # The helper method to bootstrap the Bootinq. Sets the BOOTINQ_PATH enviroment variable
    # and requires selected bundler groups.
    def require(*groups)
      ENV['BOOTINQ_PATH'] ||= File.expand_path('../bootinq.yml', caller_locations(1..1)[0].path)
      Bundler.require(*instance.groups(*groups))
    end

    private def new
      super.freeze
    end
  end
end