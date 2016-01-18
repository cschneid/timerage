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
  def self.parse_iso8601(str, exclusive_end: true)
    TimeInterval.iso8601(str, exclusive_end: exclusive_end)
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

module Kernel
  def Timerage(time_or_time_interval_ish)
    thing = time_or_time_interval_ish

    case thing
    when ->(x) { x.respond_to? :to_time_interval }
      thing

    when ->(x) { x.respond_to? :exclude_end? }
      Timerage::TimeInterval.new(thing)

    when ->(x) { x.respond_to? :to_str }
      Timerage.parse_iso8601(thing.to_str)

    when ->(x) { x.respond_to? :to_time }
      thing.to_time

    else
      fail TypeError, "unable to coerce #{thing} to a time or interval"

    end
  end
end
