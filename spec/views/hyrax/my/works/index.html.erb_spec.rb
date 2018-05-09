RSpec.describe 'hyrax/my/works/index.html.erb', type: :view do
  let(:resp) { double(docs: "", total_count: 11) }

  before do
    allow(view).to receive(:current_ability).and_return(ability)
    allow(view).to receive(:provide).and_yield
    allow(view).to receive(:provide).with(:page_title, String)
    assign(:create_work_presenter, presenter)
    assign(:response, resp)
    allow(view).to receive(:can?).and_return(true)
    allow(Flipflop).to receive(:batch_upload?).and_return(batch_enabled)
    stub_template 'shared/_select_work_type_modal.html.erb' => 'modal'
    stub_template 'hyrax/my/works/_tabs.html.erb' => 'tabs'
    stub_template 'hyrax/my/works/_search_header.html.erb' => 'search'
    stub_template 'hyrax/my/works/_document_list.html.erb' => 'list'
    stub_template 'hyrax/my/works/_results_pagination.html.erb' => 'pagination'
    stub_template 'hyrax/my/works/_scripts.js.erb' => 'batch edit stuff'
    assign(:managed_works_count, 1)
    render
  end

  context "when the user can add works" do
    let(:ability) { instance_double(Ability, can_create_any_work?: true) }
    let(:batch_enabled) { true }

    context 'with many presenters' do
      let(:presenter) { instance_double(Hyrax::SelectTypeListPresenter, many?: true) }

      it 'the line item displays the work and its actions' do
        expect(rendered).to have_selector('h1', text: 'Works')
        expect(rendered).to have_link('Create batch of works')
        expect(rendered).to have_link('Add new work')
      end

      context 'with batch_upload off' do
        let(:batch_enabled) { false }

        it 'hides batch creation button' do
          expect(rendered).not_to have_link('Create batch of works')
        end
      end
    end

    # GH-929
    context 'without many presenters' do
      let(:presenter) do
        instance_double(
          Hyrax::SelectTypeListPresenter,
          many?: false,
          first_model: GenericWork
        )
      end

      it 'the line item displays the work and its actions' do
        expect(rendered).to have_selector('h1', text: 'Works')
        expect(rendered).to have_link('Create batch of works')
        expect(rendered).to have_link('Add new work')
      end

      context 'with batch_upload off' do
        let(:batch_enabled) { false }

        it 'hides batch creation button' do
          expect(rendered).not_to have_link('Create batch of works')
        end
      end
    end
  end
end
