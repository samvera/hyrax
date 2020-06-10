# frozen_string_literal: true
RSpec.describe Hyrax::CurationConcern do
  let(:work) { GenericWork.new }
  let(:user) { double(current_user: double) }

  describe ".actor" do
    subject { described_class.actor }

    it { is_expected.to be_kind_of Hyrax::Actors::AbstractActor }
  end

  describe ".actor_factory" do
    subject { described_class.actor_factory }

    it "returns same ActionDispatch::MiddlewareStack instance" do
      is_expected.to eq described_class.actor_factory
    end
  end
end
