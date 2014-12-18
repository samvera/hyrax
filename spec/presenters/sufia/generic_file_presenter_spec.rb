require 'spec_helper'

describe Sufia::GenericFilePresenter do
  describe "#terms" do
    it "should return a list" do
      expect(described_class.terms).to eq([:resource_type, :title,
        :creator, :contributor, :description, :tag, :rights, :publisher,
        :date_created, :subject, :language, :identifier, :based_near,
        :related_url])
    end
  end
end
