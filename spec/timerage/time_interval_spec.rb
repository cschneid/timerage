require_relative "../spec_helper"

describe Timerage::TimeInterval do
  let(:now) { Time.now }
  let(:duration) { 3600 }

  describe "creation" do
    specify { expect(described_class.new(now-1..now)).to be_kind_of described_class }
    specify { expect(described_class.new(now-1, now)).to be_kind_of described_class }
    specify { expect(described_class.new(now-1, now, true)).to be_kind_of described_class }
    specify { expect(described_class.new(now-1, now, false )).to be_kind_of described_class }
  end

  describe ".iso8601" do
    specify { expect(described_class
                      .iso8601("2001-01-01T00:00:00Z/2001-01-02T00:00:00-06:00"))
                .to be_kind_of described_class }
    specify { expect{described_class.iso8601("2001-01-01T00:00:00Z")}
                .to raise_error ArgumentError }
  end

  subject(:interval) { described_class.new(now-duration, now) }

  it { is_expected.to behave_like_a Range }
  specify { expect(interval.begin).to eq now - duration }
  specify { expect(interval.end).to eq now }
  specify { expect(interval.to_time).to behave_like_a Time }
  specify { expect(interval.to_time).to (be >= interval.begin)
      .and (be <= interval.end) }
  specify { expect{|b| interval.step(1200, &b) }
      .to yield_control.at_least(:once) }
  specify { expect(interval.iso8601)
            .to eq "#{interval.begin.iso8601}/#{interval.end.iso8601}" }
  specify { expect(interval.iso8601(3))
            .to eq "#{interval.begin.iso8601(3)}/#{interval.end.iso8601(3)}" }
  specify { expect( interval.duration).to eq duration  }

  specify { expect(interval.cover? interval.begin+1..interval.end-1).to be_truthy }
  specify { expect(interval.cover? interval.begin...interval.end).to be_truthy }
  specify { expect(interval.cover? interval.begin-1..interval.end-1).to be_falsy }
  specify { expect(interval.cover? interval.begin+1..interval.end+1).to be_falsy }

  specify { expect(interval.overlap? interval.begin+1..interval.end-1).to be_truthy }
  specify { expect(interval.overlap? interval.begin...interval.end).to be_truthy }
  specify { expect(interval.overlap? interval.begin-1..interval.end-1).to be_truthy }
  specify { expect(interval.overlap? interval.begin+1..interval.end+1).to be_truthy }
  specify { expect(interval.overlap? interval.end+1..interval.end+2).to be_falsy }
  specify { expect(interval.overlap? interval.begin-2..interval.begin-1).to be_falsy }

  specify { expect(interval <=> (interval.begin-2..interval.begin-1)).to eq 1}
  specify { expect(interval <=> (interval.end+1..interval.end+2)).to eq -1}
  specify { expect(interval <=> interval).to eq 0}

  describe "==" do
    specify { expect( described_class.new(interval) == interval ).to be true }
    specify { expect( described_class.new(interval.begin, interval.end) == interval ).to be true }
  end

  describe "+" do
    let(:adjacent_preceding_time_range) { interval.begin-42..interval.begin }
    let(:adjacent_following_time_range) { interval.end..interval.end+42 }
    let(:nonadjacent_time_range) { interval.end+1..interval.end+42 }

    specify { expect( interval + adjacent_following_time_range  )
              .to be_kind_of described_class }
    specify { expect( interval + adjacent_following_time_range  )
              .to end_at adjacent_following_time_range.end }
    specify { expect( interval + adjacent_following_time_range )
              .to begin_at interval.begin }

    specify { expect( interval + adjacent_preceding_time_range )
              .to be_kind_of described_class }
    specify { expect( interval + adjacent_preceding_time_range  )
              .to end_at interval.end }
    specify { expect( interval + adjacent_preceding_time_range  )
              .to begin_at adjacent_preceding_time_range.begin }

    specify { expect{ interval + nonadjacent_time_range }.to raise_error ArgumentError }
  end


  specify { expect(interval.cover? interval.begin+1..interval.end-1).to be_truthy }
  specify { expect(interval.cover? interval.begin...interval.end).to be_truthy }
  specify { expect(interval.cover? interval.begin-1..interval.end-1).to be_falsy }
  specify { expect(interval.cover? interval.begin+1..interval.end+1).to be_falsy }

  specify { expect(interval.overlap? interval.begin+1..interval.end-1).to be_truthy }
  specify { expect(interval.overlap? interval.begin...interval.end).to be_truthy }
  specify { expect(interval.overlap? interval.begin-1..interval.end-1).to be_truthy }
  specify { expect(interval.overlap? interval.begin+1..interval.end+1).to be_truthy }
  specify { expect(interval.overlap? interval.end+1..interval.end+2).to be_falsy }
  specify { expect(interval.overlap? interval.begin-2..interval.begin-1).to be_falsy }

  specify { expect(interval <=> (interval.begin-2..interval.begin-1)).to eq 1}
  specify { expect(interval <=> (interval.end+1..interval.end+2)).to eq -1}
  specify { expect(interval <=> interval).to eq 0}

  context "inclusive end" do
    specify { expect(interval.exclude_end?).to be false }
    specify { expect(interval.cover? now).to be true }
    specify { expect(interval.cover? now - duration).to be true }
    specify { expect(interval.cover? now - (duration/2)).to be true }
    specify { expect(interval.cover? now + 1).to be false }
    specify { expect(interval.cover? now - (duration + 1)).to be false }
    specify { expect(interval.cover? interval.begin..interval.end).to be_truthy }
    specify { expect(interval.cover? interval.begin...interval.end).to be_truthy}

    specify { expect(interval.overlap? interval.begin..interval.end).to be_truthy }
    specify { expect(interval.overlap? interval.begin...interval.end).to be_truthy }
    specify { expect(interval.overlap? interval.end-1..interval.end+1).to be_truthy }
    specify { expect(interval.overlap? interval.end..interval.end+1).to be_truthy }

    specify { expect{|b| interval.step(1200, &b) }
        .to yield_successive_args now-duration, now-(duration-1200), now-(duration-2400), now }

    context "duration of non-integer steps" do
      specify { expect{|b| interval.step(1000, &b) }
          .to yield_successive_args now-duration, now-(duration-1000), now-(duration-2000), now-(duration-3000) }
    end
  end

  context "exclusive end" do
    subject(:interval) { described_class.new(now-duration...now) }

    specify { expect(interval.exclude_end?).to be true }
    specify { expect(interval.cover? now).to be false }
    specify { expect(interval.cover? now - duration).to be true }
    specify { expect(interval.cover? now - (duration/2)).to be true }
    specify { expect(interval.cover? now + 1).to be false }
    specify { expect(interval.cover? now - (duration + 1)).to be false }
    specify { expect(interval.cover? interval.end).to be false }
    specify { expect(interval.cover? interval.begin..interval.end).to be_falsy }
    specify { expect(interval.cover? interval.begin...interval.end).to be_truthy}

    specify { expect(interval.overlap? interval.begin..interval.end).to be_truthy }
    specify { expect(interval.overlap? interval.begin...interval.end).to be_truthy }
    specify { expect(interval.overlap? interval.end-1..interval.end+1).to be_truthy }
    specify { expect(interval.overlap? interval.end..interval.end+1).to be_falsy }

    specify { expect{|b| interval.step(1200, &b) }
        .to yield_successive_args now-duration, now-(duration-1200), now-(duration-2400) }

    specify { expect( interval.duration).to eq duration }
  end

  matcher :behave_like_a do |expected|
    match do |actual|
      Set[*expected.instance_methods].subset? Set[*actual.methods]
    end
  end

  matcher :begin_at do |expected|
    match do |actual|
      expect( actual.begin ).to eq expected
    end
  end

  matcher :end_at do |expected|
    match do |actual|
      expect( actual.end ).to eq expected
    end
  end
end
