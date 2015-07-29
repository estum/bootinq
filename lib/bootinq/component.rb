class Bootinq
  class Component < DelegateClass(Symbol)
    attr_reader :gem_name, :mountable, :namespace, :group
    alias :to_s :gem_name
    alias :mountable? :mountable

    def initialize(name, mountable: false)
      super(name)
      @gem_name  = name.to_s.freeze
      @mountable = !!mountable
      @group     = :"#{gem_name}_boot"
      @namespace = :"#{gem_name.camelcase}" if mountable?
      freeze
    end

    def engine
      Object.const_get(@namespace)::Engine
    end
  end
end
