RSpec.describe 'hyrax/base/_items.html.erb', type: :view do
  let(:ability) { double }
  let(:presenter) { double(:presenter, member_presenters: member_presenters, id: 'the-id', human_readable_type: 'Thing') }

  context 'when children are not present' do
    let(:member_presenters) { [] }

    context 'and the current user edit the presenter' do
      it 'renders an alert' do
        expect(view).to receive(:can?).with(:edit, presenter.id).and_return(true)
        render 'hyrax/base/items', presenter: presenter
        expect(rendered).to have_css('.alert-warning[role=alert]', text: 'This Thing has no files associated with it. Click "edit" to add more files.')
      end
    end
    context 'and the current user cannot edit the presenter' do
      it 'renders an alert' do
        expect(view).to receive(:can?).with(:edit, presenter.id).and_return(false)
        render 'hyrax/base/items', presenter: presenter
        expect(rendered).to have_css('.alert-warning[role=alert]', text: "There are no publicly available items in this Thing.")
      end
    end
  end

  context 'when children are present' do
    let(:child1) { double('Thing1', id: 'Thing 1', title: 'Title 1') }
    let(:child2) { double('Thing2', id: 'Thing 2', title: 'Title 2') }
    let(:child3) { double('Thing3', id: 'Thing 3', title: 'Title 3') }
    let(:member_presenters) { [child1, child2, child3] }
    let(:authorized_presenters) { [child1, child3] }
    let(:solr_document) { double('Solr Doc', id: 'the-id') }
    let(:presenter) { Hyrax::WorkShowPresenter.new(solr_document, ability, request) }

    before do
      stub_template 'hyrax/base/_member.html.erb' => '<%= member %>'
      expect(Flipflop).to receive(:hide_private_items?).and_return(:flipflop)
      expect(presenter).to receive(:member_presenters).and_return(member_presenters)
      expect(ability).to receive(:can?).with(:read, child1.id).and_return true
      expect(ability).to receive(:can?).with(:read, child2.id).and_return false
      expect(ability).to receive(:can?).with(:read, child3.id).and_return true
    end

    context 'and hide_private_items is on' do
      let(:flip_flop) { true }

      it "displays only authorized children" do
        render 'hyrax/base/items', presenter: presenter
        expect(rendered).to have_css('tbody', text: authorized_presenters.join)
      end
    end
    context 'and hide_private_items is off' do
      let(:flip_flop) { false }

      it "displays all children" do
        render 'hyrax/base/items', presenter: presenter
        expect(rendered).to have_css('tbody', text: member_presenters.join)
      end
    end
  end
end
