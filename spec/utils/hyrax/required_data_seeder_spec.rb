# frozen_string_literal: true
require "rails_helper"

RSpec.describe Hyrax::RequiredDataSeeder do
  describe "#generate_seed_data" do
    subject(:data_seeder) { described_class.new(logger: logger) }
    let(:logger) { double }

    it "makes the user an admin" do
      expect(Hyrax::RequiredDataSeeders::CollectionTypeSeeder)
        .to receive(:generate_seeds).with(logger: logger).once
      expect(Hyrax::RequiredDataSeeders::CollectionSeeder)
        .to receive(:generate_seeds).with(logger: logger).once
      data_seeder.generate_seed_data
    end
  end
end
