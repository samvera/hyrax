require 'spec_helper'

describe Sufia::Works::Work do
  describe ".properties" do
    subject { described_class.properties.keys }
    it { is_expected.to eq ["has_model", "create_date", "modified_date"] }
  end
end
