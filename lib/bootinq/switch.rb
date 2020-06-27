# frozen_string_literal: true

class Bootinq
  class Switch < ::BasicObject # :no-doc:
    undef_method :==
    undef_method :equal?

    module YieldMixin
      def yield_block
        yield
      end
    end

    private_constant :YieldMixin

    def self.new(*names)
      switch = super()
      mixin = ::Module.new
      mixin.include(YieldMixin)
      names.each { |name| mixin.alias_method name, :yield_block }
      mixin.send(:private, :yield_block)
      mixin.send(:extend_object, switch)
      switch
    ensure
      mixin = nil
    end

    def raise(*args) # :no-doc:
      ::Object.send(:raise, *args)
    end

    def method_missing(*)
      nil
    end
  end
end
