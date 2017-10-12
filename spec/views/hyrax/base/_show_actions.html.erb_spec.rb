RSpec.describe 'hyrax/base/_show_actions.html.erb', type: :view do
  let(:presenter) { Hyrax::WorkShowPresenter.new(solr_document, ability) }
  let(:solr_document) { SolrDocument.new(attributes) }
  let(:attributes) { { Valkyrie::Persistence::Solr::Queries::MODEL => ["GenericWork"], :id => "0r967372b" } }
  let(:ability) { double }
  let(:member) { Hyrax::WorkShowPresenter.new(member_document, ability) }
  let(:member_document) { SolrDocument.new(member_attributes) }
  let(:member_attributes) { { Valkyrie::Persistence::Solr::Queries::MODEL => ["GenericWork"], :id => "8336h190k" } }

  before do
    allow(ability).to receive(:can?).with(:create, FeaturedWork).and_return(false)
  end

  context "as an unregistered user" do
    before do
      allow(presenter).to receive(:editor?).and_return(false)
      render 'hyrax/base/show_actions.html.erb', presenter: presenter
    end
    it "doesn't show edit / delete links" do
      expect(rendered).not_to have_link 'Edit'
      expect(rendered).not_to have_link 'Delete'
    end
  end

  context "as an editor" do
    before do
      allow(presenter).to receive(:editor?).and_return(true)
    end
    context "when the work does not contain children" do
      before do
        allow(presenter).to receive(:member_presenters).and_return([])
        render 'hyrax/base/show_actions.html.erb', presenter: presenter
      end
      it "does not show file manager link" do
        expect(rendered).not_to have_link 'File Manager'
      end
      it "shows edit / delete links" do
        expect(rendered).to have_link 'Edit'
        expect(rendered).to have_link 'Delete'
      end
    end
    context "when the work contains 1 child" do
      before do
        allow(presenter).to receive(:member_presenters).and_return([member])
        render 'hyrax/base/show_actions.html.erb', presenter: presenter
      end
      it "does not show file manager link" do
        expect(rendered).not_to have_link 'File Manager'
      end
    end

    context "when the work contains 2 children" do
      let(:file_member) { Hyrax::FileSetPresenter.new(file_document, ability) }
      let(:file_document) { SolrDocument.new(file_attributes) }
      let(:file_attributes) { { id: '1234' } }

      before do
        allow(presenter).to receive(:member_presenters).and_return([member, file_member])
        render 'hyrax/base/show_actions.html.erb', presenter: presenter
      end
      it "shows file manager link" do
        expect(rendered).to have_link 'File Manager'
      end
    end
  end
end
