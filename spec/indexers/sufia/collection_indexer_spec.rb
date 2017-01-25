# frozen_string_literal: true
require 'spec_helper'

describe Sufia::CollectionIndexer do
  let(:collection) { build(:collection, id: "1234") }

  subject { described_class.new(collection).generate_solr_document }

  it "indexes thumbnail" do
    expect(subject["thumbnail_path_ss"]).to start_with("/assets/collection")
  end
end
