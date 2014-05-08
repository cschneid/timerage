require "delegate"

module Timerage
  # A range of time. The exposes the Range like interface.
  class TimeInterval < DelegateClass(Range)
    def initialize(*args)
      rng = if rangeish?(args.first)
              args.first
            else
              Range.new(*args)
            end

      super rng
    end

    alias_method :to_time, :begin

    def step(n, &blk)
      if block_given?
        time_enumerator(n).each(&blk)
      else
        time_enumerator(n)
      end
    end

    protected

    def rangeish?(an_obj)
      an_obj.respond_to?(:begin) &&
        an_obj.respond_to?(:end)
    end

    # ---
    #
    # This is implemented in a slightly more procedural style than i
    # prefer because we want to work well with ActiveSupport::Duration
    # steps. Adding a Duration to a time uses the timezone (dst, etc),
    # leap second and leap day aware `#advance` method in
    # ActiveSupport. However, multiplying a Duration by a number
    # returns a number, rather than a duration. This, in turn, means
    # that adding a duration times a number to a time results in
    # Timely incorrect results. So we do it the hard way.
    def time_enumerator(step)
      count = (self.end - self.begin).div(step)
      count += 1 if !exclude_end? and (self.end - self.begin) % step == 0
      # We've included our end if it should be

      Enumerator.new do |y|
        y << last = self.begin

        (count-1).times do
          y << last = last + step
        end
      end
    end
  end
end
