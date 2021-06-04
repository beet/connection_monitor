require "set"

=begin
Refinement to give integers, strings, and TrueClass/FalseClass `#true?` and
`#false?` predicate methods:

    using Boolean

    true.true?
    => true

    false.true?
    => false

    1.true?
    => true

    0.false?
    => true

=end
module Boolean
  TRUE_VALUES = [true, 1, "1", "t", "T", "true", "TRUE", "on", "ON"].to_set
  FALSE_VALUES = [false, 0, "0", "f", "F", "false", "FALSE", "off", "OFF"].to_set

  [
    FalseClass,
    Integer,
    String,
    TrueClass,
  ].each do |klass|
    refine klass do
      def true?
        TRUE_VALUES.include?(self)
      end

      def false?
        FALSE_VALUES.include?(self)
      end
    end
  end
end
