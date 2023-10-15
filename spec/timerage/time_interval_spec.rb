require_relative "../spec_helper"
require "active_support/all"

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

  describe "#getutc" do
    subject(:interval_utc) { described_class.new(now-duration, now).getutc }
    specify { expect(interval_utc).to be_kind_of described_class }

    context "interval not in utc" do
      specify { expect(now).not_to be_utc }
      specify { expect(interval_utc.begin).to be_utc }
      specify { expect(interval_utc.end).to be_utc }
    end

    context "interval already in utc" do
      let(:now) { Time.now.getutc }
      specify { expect(now).to be_utc }
      specify { expect(interval_utc.begin).to be_utc }
      specify { expect(interval_utc.end).to be_utc }
    end
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

  specify { expect{|b|
              Timerage(Time.parse("2019-08-01 01:00:00 UTC")...Time.parse("2019-09-01 01:00:00 UTC"))
                .step(1.month, &b)
            }.to yield_control.exactly(:once) }

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

  describe "#&" do
    specify { expect( interval & interval ).to eq interval }
    specify { expect( interval & (interval.begin-1..interval.end+1) ).to eq interval }
    specify { expect( interval & (interval.begin+1..interval.end+1) )
              .to eq interval.begin+1..interval.end }
    specify { expect( interval & (interval.begin-1..interval.end-1) )
              .to eq interval.begin..interval.end-1 }
    specify { expect( interval & (interval.begin...interval.end) ).to eq interval.begin...interval.end }
    specify { expect( interval & (interval.begin...interval.end-1) )
              .to eq interval.begin...interval.end-1 }
    specify { expect( described_class.new(interval.begin...interval.end-1) & interval )
              .to eq described_class.new(interval.begin...interval.end-1) }
  end

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
    specify { expect(interval.cover? interval.begin+1..interval.end-1).to be_truthy }
    specify { expect(interval.cover? interval.begin-1..interval.end-1).to be_falsy }
    specify { expect(interval.cover? interval.begin+1..interval.end+1).to be_falsy }

    specify { expect(interval.overlap? interval.begin..interval.end).to be_truthy }
    specify { expect(interval.overlap? interval.begin...interval.end).to be_truthy }
    specify { expect(interval.overlap? interval.end-1..interval.end+1).to be_truthy }
    specify { expect(interval.overlap? interval.end..interval.end+1).to be_truthy }
    specify { expect(interval.overlap? interval.begin-2..interval.begin-1).to be_falsy }
    specify { expect(interval.overlap? interval.end+1..interval.end+2).to be_falsy }
    specify { expect(interval.overlap? interval.begin+1..interval.end-1).to be_truthy }
    specify { expect(interval.overlap? interval.begin-1..interval.end-1).to be_truthy }
    specify { expect(interval.overlap? interval.begin+1..interval.end+1).to be_truthy }

    specify { expect{|b| interval.step(1200, &b) }
        .to yield_successive_args now-duration, now-(duration-1200), now-(duration-2400), now }

    specify { expect( interval.slice(duration/2) )
              .to eq [now-duration...now-duration/2, now-duration/2...now, now..now] }
    specify { expect( interval.slice(duration/2 + 1) )
              .to eq [now-duration...((now-duration/2)+1), (now-duration/2)+1..now] }

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

    specify { expect( interval.slice(duration/2) )
              .to eq [now-duration...now-duration/2, now-duration/2...now] }
    specify { expect( interval.slice((duration/2) + 1) )
              .to eq [now-duration...((now-duration/2)+1), (now-duration/2)+1...now] }
    specify { expect( interval.duration).to eq duration }
  end

  context "exclusive 0 length interval" do
    subject(:interval) { described_class.new(now...now) }
    specify { expect{ |b| subject.step(1, &b) }.not_to yield_control }
  end

  context "inclusive 0 length interval" do
    subject(:interval) { described_class.new(now..now) }
    specify { expect{ |b| subject.step(1, &b) }.to yield_control.once }
  end

  context "includes leap day" do
    subject(:interval) { described_class.new(before_leap_day..after_leap_day) }
    specify { expect{ |b| subject.step(1.day, &b) }.to yield_control.exactly(3).times }
    specify { expect{ |b| subject.step(86_400, &b) }.to yield_control.exactly(3).times }
  end

  context "transition into dst with explicit time zone" do
    subject(:interval) { described_class.new(before_dst..after_dst) }
    specify { expect{ |b| subject.step(1.hour, &b) }.to yield_control.exactly(2).times }
    specify { expect{ |b| subject.step(3_600, &b) }.to yield_control.exactly(2).times }
  end

  context "transition into dst without explicit time zone" do
    subject(:interval) { described_class.new(before_dst..(before_dst + 1.hour)) }
    specify { expect{ |b| subject.step(1.hour, &b) }.to yield_control.exactly(2).times }
    specify { expect{ |b| subject.step(3_600, &b) }.to yield_control.exactly(2).times }
  end

  context "When given date range" do
    it "returns date objects when stepping through the range with a day duration" do
      date_range = Date.new(2020, 1, 1)..Date.new(2020,1,3)
      described_class.new(date_range).step(1.day) do |date|
        expect(date).to be_kind_of Date
      end
    end

    it "returns Time objects when stepping through the range with an hour duration" do
      date_range = Date.new(2020, 1, 1)..Date.new(2020,1,2)
      described_class.new(date_range).step(6.hours) do |date|
        expect(date).to be_kind_of Time
      end
    end
  end

  let(:leap_day) { Time.parse("2016-02-29 12:00:00 UTC") }
  let(:before_leap_day) { leap_day - 1.day }
  let(:after_leap_day) { leap_day + 1.day}

  let(:before_dst) { Time.parse("2016-03-13 01:30:00 MST") }
  let(:after_dst) { Time.parse("2016-03-13 03:30:00 MDT") }

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
