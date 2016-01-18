require_relative "spec_helper"

describe Timerage do
  begin
    using Timerage

    subject(:range) { Range.new(now-duration, now) }

    specify { expect(range.to_time_interval).to be_kind_of Timerage::TimeInterval }
    specify { expect{|b| range.step(1200, &b) }.to yield_control.at_least(:once) }

    describe ".parse_iso8601" do
      specify { expect(described_class
                        .parse_iso8601("2001-01-01T00:00:00Z/2001-01-02T00:00:00-06:00"))
                .to be_kind_of Timerage::TimeInterval }
      specify { expect(described_class.parse_iso8601("2001-01-01T00:00:00Z"))
                .to be_kind_of Time }
    end

    context "interval include end" do
      specify { expect{|b| range.step(1200, &b) }
          .to yield_successive_args now-duration, now-(duration-1200), now-(duration-2400), now }

    end

    context "interval exclude end" do
      subject (:range) { Range.new(now-duration, now, true) }

      specify { expect{|b| range.step(1200, &b) }
          .to yield_successive_args now-duration, now-(duration-1200), now-(duration-2400) }
    end

    describe "Kernel.Timerage" do
      specify { expect( Timerage(a_time) ).to eq a_time }

      specify { expect( Timerage(a_time_interval) ).to eq a_time_interval }
      specify { expect( Timerage(a_range_of_times) ).to eq a_time_interval }

      specify { expect( Timerage(a_time.iso8601(20)) ).to eq a_time }
      specify { expect( Timerage(a_time_interval.iso8601(20)) ).to eq a_time_interval }

      specify { expect{ Timerage(nil) }.to raise_error TypeError }
      specify { expect{ Timerage(42) }.to raise_error TypeError }
    end

    let(:now) { Time.now.getutc }
    let(:a_time) { now }
    let(:a_time_interval) { Timerage::TimeInterval.new(now, now+duration, true) }
    let(:a_range_of_times) { a_time_interval.begin...a_time_interval.end }
    let(:duration) { 3600 }
  end
end
