describe Sufia::PresenterRenderer, type: :view do
  let(:file_set) { FileSet.new }
  let(:ability) { double }
  let(:presenter) { Sufia::FileSetPresenter.new(file_set.to_solr, ability) }
  let(:renderer) { described_class.new(presenter, view) }

  describe "#label" do
    context "of a field with a translation" do
      subject { renderer.label(:date_created) }
      it { is_expected.to eq 'Date Created' }
    end

    context "of a field without a translation" do
      subject { renderer.label(:date_uploaded) }
      it { is_expected.to eq 'Date uploaded' }
    end
  end
end
