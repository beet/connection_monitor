module TimeFormats
  refine Time do
    def to_time_string
      self.strftime('%R:%S')
    end
  end

  [Integer, Float].each do |klass|
    refine klass do
      def to_duration_string
        Time.at(self).gmtime.to_time_string
      end
    end
  end
end
