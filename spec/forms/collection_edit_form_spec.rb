require 'spec_helper'

describe Sufia::Forms::CollectionEditForm do
  let(:collection) { Collection.new }
  let(:form) { described_class.new(collection) }

  describe "#terms" do
    subject { form.terms}
    it { is_expected.to eq [:resource_type, :title, :creator, :contributor, :description,
                            :tag, :rights, :publisher, :date_created, :subject, :language,
                            :identifier, :based_near, :related_url] }
  end

  describe "unique?" do
    context "with :title" do
      subject { Sufia::Forms::CollectionEditForm.unique?(:title) }
      it { is_expected.to be true }
    end
  end
end
