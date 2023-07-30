# frozen_string_literal: true

class Bootinq
  def self.inflector
    @@inflector ||= Zeitwerk::Inflector.new
  end

  class Component
    # @!attribute [r] intern
    #   @return [Symbol]

    attr_reader :intern

    # @!attribute [r] id2name
    #   @return [Symbol]

    attr_reader :id2name

    # @!attribute [r] group
    #   @return [Symbol] Bundle group name

    attr_reader :group

    alias_method :to_sym, :intern
    alias_method :to_s, :id2name
    alias_method :gem_name, :id2name
    alias_method :name, :id2name

    # @see #initialize
    # @param intern [String, Symbol]
    # @return [Bootinq::Component] frozen
    def self.new(intern)
      super.freeze
    end

    # @param intern [String, Symbol]
    # @return [self]
    def initialize(intern)
      @intern = intern.to_sym
      @id2name = intern.to_s.freeze
      @group = :"#{@id2name}_boot"
    end

    # @return [Boolean]
    def mountable?
      false
    end

    # @return [Symbol]
    def module_name
      Bootinq.inflector.camelize(@id2name, nil).to_sym
    end

    # @return [Module]
    def namespace
      Object.const_get(module_name)
    end

    # @return [void]
    def engine
    end

    # @param klass [Class]
    # @return [Boolean]
    def kind_of?(klass)
      super || @intern.kind_of?(klass)
    end

    ##
    # @!group Coercing methods

    # Coerces self to other value klass.
    # @overload coerce_to(string)
    #   @param string [String]
    #   @return [String] {#id2name}
    # @overload coerce_to(symbol)
    #   @param symbol [Symbol]
    #   @return [Symbol] {#intern}
    # @overload coerce_to(other)
    #   @param other [Any]
    #   @return [self]
    def coerce_to(other)
      case other
      when String; @id2name
      when Symbol; @intern
      else self
      end
    end

    # Coerces other value
    # @overload coerce(symbol)
    #   @param symbol [Symbol]
    #   @return [Symbol] symbol
    # @overload coerce(other)
    #   @param other [String, Any]
    #   @return [String] other
    def coerce(other)
      case other
      when String, Symbol; other
      else other.to_s
      end
    end

    # @!endgroup
    ##

    ##
    # @!group Comparation methods

    # @param other [Any]
    # @return [Boolean]
    def ==(other)
      other = coerce(other)
      other == coerce_to(other)
    end

    # @param other [Any]
    # @return [Boolean]
    def ===(other)
      other = coerce(other)
      other === coerce_to(other)
    end

    # @param other [Any]
    # @return [Boolean]
    def casecmp(other)
      other = coerce(other)
      coerce_to(other).casecmp(other)
    end

    # @param other [Any]
    # @return [Boolean]
    def casecmp?(other)
      other = coerce(other)
      coerce_to(other).casecmp?(other)
    end

    # @!endgroup
    ##

    ##
    # @!group Symbol-delegated methods

    # @return [String] representation of {#intern} as a symbol literal.
    def inspect
      @intern.inspect
    end

    # @return [Proc] responded to the given method by {#intern}
    def to_proc
      @intern.to_proc
    end

    # @return [Integer] identifier for {#intern}
    def __id__
      @intern.__id__
    end

    # @return [Integer] {#intern}'s hash
    def hash
      @intern.hash
    end

    # @!endgroup
    ##

    ##
    # @!group String-delegated methods

    # @return [Encoding] of {#id2name}
    def encoding
      @id2name.encoding
    end

    # @return [Boolean]
    def empty?
      @id2name.empty?
    end

    # @return [Integer] length of {#id2name}
    def length
      @id2name.length
    end

    # @param pattern [Regexp, String]
    # @param start_from [Integer] position in {#id2name} to begin the search
    # @yield [MatchData] if match succeed
    # @yieldreturn [Any]
    # @return [MatchData] unless block given
    # @return [Any] returned by the given block
    def match(*args, &block)
      @id2name.match(*args, &block)
    end

    # @param pattern [Regexp, String]
    # @param start_from [Integer] position in {#id2name} to begin the search
    # @return [Boolean] indicates whether the regexp is matched or not
    def match?(*args)
      @id2name.match?(*args)
    end

    # @overload =~(pattern)
    #   @param pattern [Regexp]
    #   @return [Integer] if matched, the position the match starts
    #   @return [nil] if there is no match
    # @overload =~(arg)
    #   @param arg [Object]
    #   @see Object#=~
    def =~(arg)
      @id2name =~ arg
    end

    # Element reference
    # @see String#slice
    def slice(*args)
      @id2name[*args]
    end

    alias_method :[], :slice

    # @!endgroup
    ##

    ##
    # @!group Symbol-delegated mutation methods

    # @see Symbol#upcase
    # @return [Bootinq::Component] new instance with upcased {#intern}
    def upcase
      self.class.new(@intern.upcase)
    end

    # @see Symbol#downcase
    # @return [Bootinq::Component] new instance with downcased {#intern}
    def downcase
      self.class.new(@intern.downcase)
    end

    # @see Symbol#capitalize
    # @return [Bootinq::Component] new instance with capitalized {#intern}
    def capitalize
      self.class.new(@intern.capitalize)
    end

    # @see Symbol#swapcase
    # @return [Bootinq::Component] new instance with swapcased {#intern}
    def swapcase
      self.class.new(@intern.swapcase)
    end

    # @see Symbol#succ
    # @return [Bootinq::Component] new instance with the successor {#intern}
    def succ
      self.class.new(@intern.succ)
    end

    # @see Symbol#next
    # @return [Bootinq::Component] new instance with the next {#intern}
    def next
      self.class.new(@intern.next)
    end

    # @endgroup
    ##
  end

  class Mountable < Component
    # @!attribute [r] module_name
    #   @return [Symbol]

    # @!attribute [r] namespace
    #   @return [Module]

    def initialize(intern)
      super
      @module_name = module_name()
      @namespace = namespace()
    end

    def mountable?
      true
    end

    def module_name
      return @module_name if frozen? || defined?(@module_name)
      super
    end

    def namespace
      if frozen? || defined?(@namespace)
        @namespace.is_a?(Proc) ? @namespace.call : @namespace
      elsif namespace_defined?
        super
      else
        proc { super }
      end
    end

    # @return [Class]
    def engine
      namespace::Engine
    end

    private

    # @api private
    def namespace_defined?
      Object.const_defined?(module_name)
    end
  end
end
