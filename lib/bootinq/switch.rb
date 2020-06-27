# frozen_string_literal: true

class Bootinq
  class Switch < ::BasicObject # :no-doc:
    undef_method :==
    undef_method :equal?

    def raise(*args) # :no-doc:
      ::Object.send(:raise, *args)
    end

    def method_missing(name, *)
      if ::Bootinq.enabled?(name)
        yield()
      else
        nil
      end
    end
  end
end
