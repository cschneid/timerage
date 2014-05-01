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

    def time_enumerator(step)
      not_done = if exclude_end?
                   ->(nxt) { nxt < self.end }
                 else
                   ->(nxt) { nxt <= self.end }
                 end

      Enumerator.new do |y|
        nxt = self.begin

        while not_done.call(nxt) do
          y << nxt

          nxt += step
        end
      end
    end
  end
end
