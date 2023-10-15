require "delegate"

module Timerage
  # A range of time. The exposes the Range like interface.
  class TimeInterval < Range

    class << self
      def new(*args)
        args = [args.first.begin, args.first.end, args.first.exclude_end?] if args.first.respond_to?(:exclude_end?)
        new_obj = allocate
        new_obj.send(:initialize, *args)
        new_obj
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

    def slice(seconds)
      time_enumerator(seconds)
        .map{|t|
          end_time = [t+seconds, self.end].min
          inclusive = (t == end_time || t+seconds > self.end) && !exclude_end?
          TimeInterval.new(t, end_time, !inclusive) }
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

    def time_enumerator(step)
      next_offset = (self.begin + step).is_a?(Date) ? 0.days : 0.seconds

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
