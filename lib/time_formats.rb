require "date"

module TimeFormats
  [Time, Date].each do |klass|
    refine klass do
      def long_time_string
        self.strftime('%Y-%m-%d %R:%S')
      end

      def short_time_string
        self.strftime('%R:%S')
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
