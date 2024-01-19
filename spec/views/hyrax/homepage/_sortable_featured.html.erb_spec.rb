# frozen_string_literal: true
RSpec.describe 'hyrax/homepage/_sortable_featured.html.erb', type: :view do
  let(:form_builder) { double }
  let(:work) do
    stub_model(
      GenericWork,
      id: "99",
      title: ['Foo'],
      created_at: DateTime.now,
      updated_at: DateTime.now,
      internal_resource: 'GenericWork',
      alternate_ids: []
    )
  end
  let(:featured_work) { FeaturedWork.create(work_id: "99", presenter: presenter) }
  let(:presenter) { Hyrax::WorkShowPresenter.new(SolrDocument.new(Hyrax::ValkyrieIndexer.for(resource: work).to_solr), nil) }
  let(:page) { rendered }

  before do
    # https://github.com/samvera/active_fedora/issues/1251
    allow(work).to receive(:persisted?).and_return(true)
    allow(view).to receive(:f).and_return(form_builder)
    allow(form_builder).to receive(:object).and_return(featured_work)
    allow(form_builder).to receive(:hidden_field)
    allow(work).to receive(:hydra_model).and_return(GenericWork)
    allow(view).to receive(:render_thumbnail_tag).and_return("thumbnail")
    allow(view).to receive(:can?).with(:destroy, FeaturedWork).and_return(false)
    render
  end

  it "enables featured works to be sorted" do
    expect(page).to include('<div class="dd-handle dd3-handle">Drag</div>')
  end
end
