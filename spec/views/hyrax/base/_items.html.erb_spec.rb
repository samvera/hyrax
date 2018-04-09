RSpec.describe 'hyrax/base/_items.html.erb', type: :view do
  let(:ability) { double }
  let(:presenter) { double(:presenter, member_presenters: member_presenters, id: 'the-id', human_readable_type: 'Thing') }

  context 'when children are not present' do
    let(:member_presenters) { [] }

    context 'and the current user edit the presenter' do
      it 'renders an alert' do
        expect(view).to receive(:can?).with(:edit, presenter.id).and_return(true)
        render 'hyrax/base/items', presenter: presenter
        expect(rendered).to have_css('.alert-warning[role=alert]')
      end
    end
    context 'and the current user cannot edit the presenter' do
      it 'does not render an alert' do
        expect(view).to receive(:can?).with(:edit, presenter.id).and_return(false)
        render 'hyrax/base/items', presenter: presenter
        expect(rendered).not_to have_css('.alert-warning[role=alert]')
      end
    end
  end

  context "when children are present" do
    let(:member_presenters) { ['Thing One', 'Thing Two'] }

    before do
      stub_template 'hyrax/base/_member.html.erb' => '<%= member %>'
    end
    it "links to child work" do
      render 'hyrax/base/items', presenter: presenter
      expect(rendered).to have_css('tbody', text: member_presenters.join)
    end
  end

  context "when file set members are present" do
    let(:user) { create(:user) }
    let(:ability) { Ability.new(user) }
    let(:file1) { create(:file_set, :public) }
    let(:file2) { create(:file_set) }

    let(:solr_document) { SolrDocument.new(attributes) }
    let(:presenter) { Hyrax::WorkShowPresenter.new(solr_document, ability, request) }

    before do
      stub_template 'hyrax/base/_member.html.erb' => '<%= member %>'
    end

    context "and a public file set" do
      let(:attributes) { create(:public_work, ordered_members: [file1]).to_solr }

      it "show the link for the file set" do
        expect(Flipflop).to receive(:hide_private_files?).and_return(true)
        render 'hyrax/base/items', presenter: presenter
        expect(rendered).to have_content presenter.member_presenters.first.link_name
      end
    end

    context "and a private file set" do
      let(:attributes) { create(:public_work, ordered_members: [file2]).to_solr }

      it "won't show the link to the file set" do
        expect(Flipflop).to receive(:hide_private_files?).and_return(true)
        expect(view).to receive(:can?).with(:edit, presenter.id).and_return(false)
        render 'hyrax/base/items', presenter: presenter
        expect(rendered).not_to have_content presenter.member_presenters.first.link_name
      end
    end

    context "with public and private file sets" do
      let(:attributes) { create(:public_work, ordered_members: [file1, file2]).to_solr }

      it "only show the link to the file set that users have permission to see" do
        expect(Flipflop).to receive(:hide_private_files?).and_return(true)
        render 'hyrax/base/items', presenter: presenter
        expect(rendered).to have_content presenter.member_presenters.first.link_name
        expect(rendered).not_to have_content presenter.member_presenters[1].link_name
      end
    end
  end
end
