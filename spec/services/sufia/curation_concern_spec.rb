require 'spec_helper'

describe Sufia::CurationConcern do
  let(:work) { GenericWork.new }
  let(:user) { double }

  describe ".actor" do
    subject { described_class.actor(work, user) }
    it { is_expected.to be_kind_of Sufia::Actors::ActorStack }
  end
end
