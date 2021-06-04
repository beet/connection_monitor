require "date"

=begin
Refinement for presenting Time objects as formatted strings:

    using TimeFormats

    time = Time.now

    time.long_time_string
    => "2021-06-04 15:20:33"

    time.short_time_string
    => "15:20:33"

    time.to_date_string
    => "Fri 04 Jun, 2021-06-04"
=end
module TimeFormats
  [Time, Date].each do |klass|
    refine klass do
      def long_time_string
        strftime('%Y-%m-%d %R:%S')
      end

      def short_time_string
        strftime('%R:%S')
      end

      def to_date_string
        strftime("%a %d %b, %Y-%m-%d")
      end
    end
  end

  [Integer, Float].each do |klass|
    refine klass do
      def to_duration_string
        Time.at(self).gmtime.strftime("%R:%S")
      end
    end
  end
end
