# frozen_string_literal: true
require "rails_helper"

RSpec.describe Hyrax::DataMaintenance do
  describe "#destroy_repository_metadata_and_related_data" do
    subject(:destroyer) { described_class.new(logger: logger) }
    let(:logger) { double }

    it "calls seeders" do
      call_all_destroyers_with(allow_destruction_in_production: false)
      destroyer.destroy_repository_metadata_and_related_data
    end

    context "when in production" do
      before { allow(Rails.env).to receive(:production?).and_return(true) }
      it "raises exception" do
        expect { described_class.new(logger: logger) }
          .to raise_error(RuntimeError, "Destruction of data is not for use in production!")
      end

      context "and allow_destruction_in_production=true" do
        it "calls seeders" do
          call_all_destroyers_with(allow_destruction_in_production: true)
          destroyer = described_class.new(logger: logger, allow_destruction_in_production: true)
          destroyer.destroy_repository_metadata_and_related_data
        end
      end
    end
  end

  def call_all_destroyers_with(allow_destruction_in_production:) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    expect(Hyrax::DataDestroyers::RepositoryMetadataDestroyer)
      .to receive(:destroy_metadata)
      .with(logger: logger,
            allow_destruction_in_production: allow_destruction_in_production)
      .once
    expect(Hyrax::DataDestroyers::StatsDestroyer)
      .to receive(:destroy_data)
      .with(logger: logger,
            allow_destruction_in_production: allow_destruction_in_production)
      .once
    expect(Hyrax::DataDestroyers::FeaturedWorksDestroyer)
      .to receive(:destroy_data)
      .with(logger: logger,
            allow_destruction_in_production: allow_destruction_in_production)
      .once
    expect(Hyrax::DataDestroyers::PermissionTemplatesDestroyer)
      .to receive(:destroy_data)
      .with(logger: logger,
            allow_destruction_in_production: allow_destruction_in_production)
      .once
    expect(Hyrax::DataDestroyers::CollectionBrandingDestroyer)
      .to receive(:destroy_data)
      .with(logger: logger,
            allow_destruction_in_production: allow_destruction_in_production)
      .once
    expect(Hyrax::DataDestroyers::DefaultAdminSetIdCacheDestroyer)
      .to receive(:destroy_data)
      .with(logger: logger,
            allow_destruction_in_production: allow_destruction_in_production)
      .once
    expect(Hyrax::DataDestroyers::CollectionTypesDestroyer)
      .to receive(:destroy_data)
      .with(logger: logger,
            allow_destruction_in_production: allow_destruction_in_production)
      .once
  end
end
