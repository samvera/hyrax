require 'spec_helper'

describe RightsService do
  describe "select_options" do
    subject { described_class.select_options }

    it "has a select list" do
      expect(subject.first).to eq ["Attribution 3.0 United States", "http://creativecommons.org/licenses/by/3.0/us/"]
    end
  end

  describe "label" do
    subject { described_class.label("http://www.europeana.eu/portal/rights/rr-r.html") }

    it { is_expected.to eq 'All rights reserved' }
  end
end
