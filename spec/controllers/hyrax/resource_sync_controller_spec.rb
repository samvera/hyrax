# frozen_string_literal: true
RSpec.describe Hyrax::ResourceSyncController do
  before do
    Rails.cache.clear
  end

  describe "source_description" do
    let(:writer) { double }
    let(:document) { '<xml>' }
    let(:capability_list) { Hyrax::Engine.routes.url_helpers.capability_list_url(host: 'test.host') }

    it "is successful" do
      allow(Hyrax::ResourceSync::SourceDescriptionWriter).to receive(:new).with(capability_list_url: capability_list).and_return(writer)
      expect(writer).to receive(:write).and_return(document)
      get :source_description
      expect(response.media_type).to eq 'application/xml'
      expect(response.body).to eq document
    end
  end

  describe "capability_list" do
    let(:writer) { double }
    let(:document) { '<xml>' }
    let(:capability_list) { Hyrax::Engine.routes.url_helpers.capability_list_url(host: 'test.host') }

    it "is successful" do
      allow(Hyrax::ResourceSync::CapabilityListWriter).to receive(:new).with(resource_list_url: "http://test.host/resourcelist",
                                                                             change_list_url: "http://test.host/changelist",
                                                                             description_url: "http://test.host/.well-known/resourcesync").and_return(writer)
      expect(writer).to receive(:write).and_return(document)
      get :capability_list
      expect(response.media_type).to eq 'application/xml'
      expect(response.body).to eq document
    end
  end

  describe "resource_list" do
    before do
      Rails.cache.clear
    end

    let(:writer) { double }
    let(:document) { '<xml>' }
    let(:capability_list) { Hyrax::Engine.routes.url_helpers.capability_list_url(host: 'test.host') }

    it "is successful" do
      allow(Hyrax::ResourceSync::ResourceListWriter).to receive(:new).with(capability_list_url: capability_list, resource_host: "test.host").and_return(writer)
      expect(writer).to receive(:write).and_return(document)
      get :resource_list
      expect(response.media_type).to eq 'application/xml'
      expect(response.body).to eq document
    end
  end

  describe "change_list" do
    before do
      Rails.cache.clear
    end

    let(:writer) { double }
    let(:document) { '<xml>' }
    let(:capability_list) { Hyrax::Engine.routes.url_helpers.capability_list_url(host: 'test.host') }

    it "is successful" do
      allow(Hyrax::ResourceSync::ChangeListWriter).to receive(:new).with(capability_list_url: capability_list, resource_host: "test.host").and_return(writer)
      expect(writer).to receive(:write).and_return(document)
      get :change_list
      expect(response.media_type).to eq 'application/xml'
      expect(response.body).to eq document
    end
  end
end
