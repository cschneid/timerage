require "timerage/version"
require "time"

module Timerage
  autoload :TimeInterval, "timerage/time_interval"

  # Returns a Time or Timerage::TimeInterval representation of the
  # iso8601 str.
  #
  # --
  #
  # Currently this only supports `<begin>/<end>` style time intervals.
  def self.parse_iso8601(str)
    TimeInterval.iso8601(str)
  rescue ArgumentError
    Time.iso8601(str)
  end

  refine Range do
    def step(n, &blk)
      if self.begin.kind_of?(Time) || self.begin.kind_of?(Date)
        Timerage::TimeInterval.new(self).step(n, &blk)
      else
        super
      end
    end

    def to_time_interval
      Timerage::TimeInterval.new(self)
    end
  end
end
