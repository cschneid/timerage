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

    # Returns number of seconds in this interval
    def duration
      self.end - self.begin
    end

    def step(n, &blk)
      if block_given?
        time_enumerator(n).each(&blk)
      else
        time_enumerator(n)
      end
    end

    def slice(seconds)
      time_enumerator(seconds)
        .map{|t|
          end_time = [t+seconds, self.end].min
          inclusive = (self.end == t && !exclude_end?) || t+seconds > self.end
          TimeInterval.new(t, end_time, !inclusive) }
    end

    def ==(other)
      self.begin == other.begin &&
        self.end == other.end &&
        self.exclude_end? == other.exclude_end?

    rescue NoMethodError
      false
    end

    # Return new TimeInterval that is the concatenation of self and
    # other (if possible).
    #
    # Raises ArgumentError if other is not adjacent to self
    # chronologically.
    def +(other)
      fail ArgumentError, "other must be adjacent to self" unless adjacent_to?(other)

      self.class.new([self.begin, other.begin].min, [self.end, other.end].max)
    end

    # Returns an ISO8601 interval representation of self
    # Takes same args as Time#iso8601
    def iso8601(*args)
      "#{self.begin.iso8601(*args)}/#{self.end.iso8601(*args)}"
    end

    def adjacent_to?(other)
      other.begin == self.end || other.end == self.begin
    end

    def cover?(time_or_interval)
      return super unless rangeish?(time_or_interval)

      other = time_or_interval

      self.begin <= other.begin &&
        if self.exclude_end? && other.exclude_end?
          self.end > other.begin && self.begin < other.end && other.end <= self.end

        elsif self.exclude_end?
          self.end > other.begin && self.begin <= other.end && other.end < self.end

        elsif other.exclude_end?
          self.end >= other.begin && self.begin < other.end && other.end <= self.end

        else
          self.end >= other.begin && self.begin <= other.end && other.end <= self.end
        end
    end

    def overlap?(other)
      cover?(other) ||
        other.cover?(self) ||
        cover?(other.begin) ||
        other.cover?(self.begin) ||
        cover?(other.end) && (!other.exclude_end? || other.end != self.begin) ||
        other.cover?(self.end) && (!self.exclude_end? || other.begin != self.end)
    end

    def <=>(other)
      return super unless rangeish?(other)

      self.begin <=> other.begin
    end

    def ==(other)
      self.begin == other.begin &&
        self.end == other.end &&
        self.exclude_end? == other.exclude_end?

    rescue NoMethodError
      false
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
      count = (self.end - self.begin).div(step) + 1
      count -= 1 if exclude_end? and (self.end - self.begin) % step == 0
      # We've included our end if it should be

      Enumerator.new do |y|
        y << last = self.begin

        (count-1).times do
          y << last = last + step
        end
      end
    end

    # class methods
    # =============

    # Returns a new TimeInterval representation of the iso8601 interval
    # represented by the specified string.
    #
    # --
    #
    # Currently this only supports `<begin>/<end>` style time intervals.
    def self.iso8601(str)
      new *str.split("/").map{|s| Time.iso8601(s)}

    rescue ArgumentError
      raise ArgumentError, "Invalid iso8601 interval: #{str.inspect}"
    end
  end
end
