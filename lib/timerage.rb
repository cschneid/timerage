require "timerage/version"

module Timerage
  refine Range do
    def step(n, &blk)
      if self.begin.kind_of?(Time) || self.begin.kind_of?(Date)
        if block_given?
          time_enumerator(n).each(&blk)
        else
          time_enumerator(n)
        end
      else
        super
      end
    end

    def time_enumerator(step)
      Enumerator.new do |y|
        nxt = self.begin

        while nxt <= self.end do
          y << nxt

          nxt += step
        end
      end
    end
  end
end
