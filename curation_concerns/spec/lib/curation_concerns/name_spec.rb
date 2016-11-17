require 'spec_helper'

describe CurationConcerns::Name do
  let(:name) { described_class.new(GenericWork) }

  describe "route_key" do
    subject { name.route_key }
    it { is_expected.to eq 'curation_concerns_generic_works' }
  end

  describe "singular_route_key" do
    subject { name.singular_route_key }
    it { is_expected.to eq 'curation_concerns_generic_work' }
  end

  describe "param_key" do
    subject { name.param_key }
    it { is_expected.to eq 'generic_work' }
  end
end
