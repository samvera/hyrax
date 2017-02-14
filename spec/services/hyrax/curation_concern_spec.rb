require 'spec_helper'

describe Hyrax::CurationConcern do
  let(:work) { GenericWork.new }
  let(:user) { double(current_user: double) }

  describe ".actor" do
    subject { described_class.actor(work, user) }
    it { is_expected.to be_kind_of Hyrax::Actors::ActorStack }
  end
end
