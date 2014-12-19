require 'spec_helper'

describe Sufia::Forms::GenericFileEditForm do
  subject { described_class.new(GenericFile.new) }

  describe "#terms" do
    it "should return a list" do
      expect(subject.terms).to eq([:resource_type, :title, :creator, :contributor, :description, :tag,
                    :rights, :publisher, :date_created, :subject, :language, :identifier, :based_near, :related_url])
    end
  end

  it "should initialize multivalued fields" do
    expect(subject.title).to eq ['']
  end

  describe ".model_attributes" do
    let(:params) { ActionController::Parameters.new(title: ['foo'], description: [''])}
    subject { described_class.model_attributes(params) }

    it "should only change title" do
      expect(subject['title']).to eq ["foo"]
      expect(subject['description']).to be_empty
    end
  end
end
