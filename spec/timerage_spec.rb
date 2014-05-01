require_relative "spec_helper"

describe Timerage do
  begin
    using Timerage

    subject(:range) { Range.new(now-duration, now) }

    specify { expect(range.to_time_interval).to be_kind_of Timerage::TimeInterval }
    specify { expect{|b| range.step(1200, &b) }.to yield_control.at_least(:once) }

    context "interval include end" do
      specify { expect{|b| range.step(1200, &b) }
          .to yield_successive_args now-duration, now-(duration-1200), now-(duration-2400), now }

  end

    context "interval exclude end" do
      subject (:range) { Range.new(now-duration, now, true) }

      specify { expect{|b| range.step(1200, &b) }
          .to yield_successive_args now-duration, now-(duration-1200), now-(duration-2400) }
    end

    let(:now) { Time.now }
    let(:duration) { 3600 }
  end
end
