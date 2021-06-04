=begin
Module for providing predicate method accessors for instance variables.

Before:

    class Foo
      attr_reader :bar

      def initialize
        @bar = true
      end

      def bar?
        bar
      end
    end

    Foo.new.bar?
    => true

After:

    class Foo
      include PredicateAttributes

      def initialize
        @bar = "true"
      end
    end

    Foo.new.bar?
    => true

    Foo.new.bar
    => true

=end
module PredicateAttributes
  using Boolean

  def method_missing(method_name)
    if has_predicate_attribute_for?(method_name)
      instance_variable_get(instance_variable_sym_for(method_name)).true?
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_all = false)
    has_predicate_attribute_for?(method_name) || super
  end

  private

  def has_predicate_attribute_for?(method_name)
    return false unless instance_variables.include?(instance_variable_sym_for(method_name))

    method_name.match?(/^[^?]+\??$/)
  end

  def instance_variable_sym_for(method_name)
    "@#{method_name}".chomp("?").to_sym
  end
end
