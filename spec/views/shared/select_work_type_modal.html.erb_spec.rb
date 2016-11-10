require 'spec_helper'

RSpec.describe 'shared/_select_work_type_modal.html.erb', type: :view do
  let(:presenter) { instance_double Sufia::SelectTypeListPresenter }
  let(:row1) do
    instance_double(Sufia::SelectTypePresenter,
                    icon_class: 'icon',
                    name: 'Generic Work',
                    description: 'Workhorse',
                    concern: GenericWork)
  end
  let(:row2) do
    instance_double(Sufia::SelectTypePresenter,
                    icon_class: 'icon',
                    name: 'Book',
                    description: 'Book of things',
                    concern: other_model)
  end
  let(:other_model) do
    double(persisted?: false,
           model_name: double(singular_route_key: 'foo', param_key: 'foo'))
  end
  before do
    allow(presenter).to receive(:each).and_yield(row1).and_yield(row2)
    allow(view).to receive(:new_polymorphic_path).and_return('/foos/new')
    allow(view).to receive(:create_work_presenter).and_return(presenter)
    render
  end
  let(:results) { [GenericWork, other_model] }

  it "draws the modal" do
    expect(rendered).to have_selector "#worktypes-to-create.modal"
    expect(rendered).to have_link "Book", href: '/foos/new'
    expect(rendered).to have_link "Generic Work"
  end
end
