# frozen_string_literal: true

class Bootinq
  class Component
    attr_reader :intern, :id2name, :group

    alias :to_sym   :intern
    alias :to_s     :id2name
    alias :gem_name :id2name
    alias :name     :id2name

    def initialize(intern)
      @intern  = intern.to_sym
      @id2name = intern.to_s.freeze
      @group   = :"#@id2name\_boot"
      freeze
    end

    def mountable?
      false
    end

    def module_name
      @id2name.camelcase.to_sym
    end

    def engine
    end

    def kind_of?(klass)
      super || @intern.kind_of?(klass)
    end

    def == other
      case other
      when String then other == @id2name
      when Symbol then other == @intern
                  else super
      end
    end

    def ===(other)
      case other
      when String then other === @id2name
      when Symbol then other === @intern
                  else super
      end
    end

    def casecmp(other)
      case other
      when String then @id2name.casecmp(other)
      when Symbol then @intern.casecmp(other)
      when self.class then casecmp(other.to_s)
      end
    end

    def casecmp?(other)
      case other
      when String then @id2name.casecmp?(other)
      when Symbol then @intern.casecmp?(other)
      when self.class then casecmp?(other.to_s)
      end
    end

    %i(inspect to_proc __id__ hash).
      each { |sym| class_eval %(def #{sym}; @intern.#{sym}; end), __FILE__, __LINE__ + 1 }

    %i(encoding empty? length).
      each { |sym| class_eval %(def #{sym}; @id2name.#{sym}; end), __FILE__, __LINE__ + 1 }

    %i(match match? =~ []).
      each { |sym| class_eval %(def #{sym}(*args); @id2name.#{sym}(*args); end), __FILE__, __LINE__ + 1 }

    %i(upcase downcase capitalize swapcase succ next).
      each { |sym| class_eval %(def #{sym}; self.class.new(@intern.#{sym}); end), __FILE__, __LINE__ + 1 }

    alias :slice :[]
    alias :size :length
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
