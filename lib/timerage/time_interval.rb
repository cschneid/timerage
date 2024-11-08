require "delegate"

module Timerage
  # A range of time. The exposes the Range like interface.
  class TimeInterval < Range

    class << self
      # Returns a new TimeInterval
      #
      # start_time - the beginning of the interval
      # end_time   - the end of the interval
      # exclude_end - whether the end time is excluded from the interval
      def new(*args)
        return from_range(*args) if args.first.respond_to?(:exclude_end?)

        super
      end

      # Returns a new TimeInterval
      #
      # time - the beginning or end of the interval
      # duration - the duration of the interval, if negative the
      #   interval will start before`time`
      # exclude_end - whether the end time is excluded from the interval
      def from_time_and_duration(time, duration, exclude_end: true)
        if duration >= 0
          new(time, time + duration, exclude_end)
        else
          new(time + duration, time, exclude_end)
        end
      end 

      # Returns a new TimeInterval based on the specified range 
      def from_range(range)
        new(range.begin, range.end, range.exclude_end?)
      end
    end

    def to_time_interval
      self
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

    def slice(duration)
      time_enumerator(duration)
        .each_cons(2).map { |s_begin, s_end| TimeInterval.new(s_begin, s_end, exclusive_end_slice?(s_end)) }
        .then do |slices|
          slices << TimeInterval.new(slices.last.end, self.end, exclusive_end_slice?(slices.last.end + duration)) if slices.present?
        end
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

    def getutc
      return self if self.begin.utc? && self.end.utc?
      self.class.new(self.begin.getutc, self.end.getutc, self.exclude_end?)
    end

    def adjacent_to?(other)
      other.begin == self.end || other.end == self.begin
    end

    def cover?(time_or_interval)
      other = time_or_interval
      return super unless rangeish?(other)
      return false unless overlap?(other)

      self_end, other_end = self.end, other.end
      other.begin >= self.begin &&
        if !self.exclude_end? || other.exclude_end?
          other_end <= self_end
        else
          other_end < self_end
        end
    end

    def overlap?(other)
      if self.begin <= other.begin
        earliest, latest = self, other
      else
        earliest, latest = other, self
      end

      latest_begin, earliest_end = latest.begin, earliest.end
      return true  if latest_begin < earliest_end
      return false if earliest_end < latest_begin

      !earliest.exclude_end?
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

    # Returns a new TimeInterval that is the intersection of `self` and `other`.
    def &(other)
      fail ArgumentError, "#{other} does not overlap #{self}" unless self.overlap? other

      new_begin = [self.begin, other.begin].max
      new_end,ex_end = if self.end > other.end
                         [other.end, other.exclude_end?]
                       elsif self.end < other.end
                         [self.end, self.exclude_end?]
                       elsif self.exclude_end? || other.exclude_end?
                         [self.end, true]
                       else
                         [self.end, false]
                       end

      self.class.new(new_begin, new_end, ex_end)
    end

    protected

    def rangeish?(an_obj)
      an_obj.respond_to?(:begin) &&
        an_obj.respond_to?(:end)
    end

    def exclusive_end_slice?(slice_end)
      !((slice_end > self.end) && !exclude_end?)
    end

    def time_enumerator(step)
      next_offset = step * 0

      Enumerator.new do |y|
        while self.cover?(self.begin + next_offset)
          y << self.begin + next_offset
          next_offset += step
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
    def self.iso8601(str, exclusive_end: true)
      new *str.split("/", 2).map{|s| Time.iso8601(s)}, exclusive_end

    rescue ArgumentError
      raise ArgumentError, "Invalid iso8601 interval: #{str.inspect}"
    end
  end

end
