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

  context "interval include end" do
    specify { expect(interval.exclude_end?).to be false }
    specify { expect(interval.cover? now).to be true }
    specify { expect(interval.cover? now - duration).to be true }
    specify { expect(interval.cover? now - (duration/2)).to be true }
    specify { expect(interval.cover? now + 1).to be false }
    specify { expect(interval.cover? now - (duration + 1)).to be false }

    specify { expect{|b| interval.step(1200, &b) }
        .to yield_successive_args now-duration, now-(duration-1200), now-(duration-2400), now }

    context "duration of non-integer steps" do
      specify { expect{|b| interval.step(1000, &b) }
          .to yield_successive_args now-duration, now-(duration-1000), now-(duration-2000), now-(duration-3000) }
    end
  end

  context "interval exclude end" do
    subject(:interval) { described_class.new(now-duration...now) }

    specify { expect(interval.exclude_end?).to be true }
    specify { expect(interval.cover? now).to be false }
    specify { expect(interval.cover? now - duration).to be true }
    specify { expect(interval.cover? now - (duration/2)).to be true }
    specify { expect(interval.cover? now + 1).to be false }
    specify { expect(interval.cover? now - (duration + 1)).to be false }

    specify { expect{|b| interval.step(1200, &b) }
        .to yield_successive_args now-duration, now-(duration-1200), now-(duration-2400) }

  end

  matcher :behave_like_a do |expected|
    match do |actual|
      Set[*expected.instance_methods].subset? Set[*actual.methods]
    end
  end
end
