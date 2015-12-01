require 'spec_helper'

describe Sufia::Forms::WorkForm do
  describe "#rendered_terms" do
    subject { described_class.new(GenericWork.new, nil).rendered_terms }
    it { is_expected.not_to include(:visibilty) }
  end
end
