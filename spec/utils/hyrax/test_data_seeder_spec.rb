# frozen_string_literal: true
require "rails_helper"

RSpec.describe Hyrax::TestDataSeeder do
  describe "#generate_seed_data" do
    subject(:data_seeder) { described_class.new(logger: logger) }
    let(:logger) { double }

    it "calls seeders" do
      call_all_seeders_with(allow_seeding_in_production: false)
      data_seeder.generate_seed_data
    end

    context "when in production" do
      before { allow(Rails.env).to receive(:production?).and_return(true) }
      it "raises exception" do
        expect { described_class.new(logger: logger) }
          .to raise_error(RuntimeError, "TestDataSeeder is not for use in production!")
      end

      context "and allow_seeding_in_production=true" do
        it "calls seeders" do
          call_all_seeders_with(allow_seeding_in_production: true)
          data_seeder = described_class.new(logger: logger, allow_seeding_in_production: true)
          data_seeder.generate_seed_data
        end
      end
    end
  end

  def call_all_seeders_with(allow_seeding_in_production:) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    expect(Hyrax::TestDataSeeders::UserSeeder)
      .to receive(:generate_seeds)
      .with(logger: logger,
            allow_seeding_in_production: allow_seeding_in_production)
      .once
    expect(Hyrax::TestDataSeeders::CollectionTypeSeeder)
      .to receive(:generate_seeds)
      .with(logger: logger,
            allow_seeding_in_production: allow_seeding_in_production)
      .once
    expect(Hyrax::TestDataSeeders::CollectionSeeder)
      .to receive(:generate_seeds)
      .with(logger: logger,
            allow_seeding_in_production: allow_seeding_in_production)
      .once
  end
end
