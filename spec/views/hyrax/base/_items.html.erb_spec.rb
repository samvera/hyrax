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
end
