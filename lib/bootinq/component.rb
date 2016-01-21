class Bootinq
  class Component
    attr_reader :intern, :id2name

    alias :to_sym   :intern
    alias :to_s     :id2name
    alias :gem_name :id2name
    alias :name     :id2name

    def initialize(intern)
      @intern  = intern.to_sym
      @id2name = intern.to_s.freeze
      freeze
    end

    def mountable?
      false
    end

    def group
      :"#@id2name\_boot"
    end

    def == other
      case other
      when String then other == @id2name
      when Symbol then other == @intern
                  else super
      end
    end

    def inspect
      @intern.inspect
    end

    def engine
      nil
    end

    def module_name
      @id2name.camelcase.to_sym
    end

    def respond_to_missing?(method_name, include_all=false)
      @intern.respond_to?(method_name, include_all)
    end

    private

    def method_missing(method_name, *args, &blk)
      @intern.respond_to?(method_name) ? @intern.public_send(method_name, *args, &blk) : super
    end
  end

  class Mountable < Component
    def mountable?
      true
    end

    def engine
      Object.const_get(module_name)::Engine
    end
  end
end
