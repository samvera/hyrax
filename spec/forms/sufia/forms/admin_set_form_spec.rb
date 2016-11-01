require 'spec_helper'
RSpec.describe Sufia::Forms::AdminSetForm do
  let(:permission_template) { double }
  let(:form) { described_class.new(model, permission_template) }

  describe "[] accessors" do
    let(:model) { AdminSet.new(description: ['one']) }
    it "cast to scalars" do
      expect(form[:description]).to eq 'one'
    end
  end

  describe "model_attributes" do
    let(:raw_attrs) { ActionController::Parameters.new(title: 'test title') }
    subject { described_class.model_attributes(raw_attrs) }

    it "casts to enums" do
      expect(subject[:title]).to eq ['test title']
    end
  end
end
