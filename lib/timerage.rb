require "timerage/version"

module Timerage
  autoload :TimeInterval, "timerage/time_interval"

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
