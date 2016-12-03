describe 'hyrax/homepage/_sortable_featured.html.erb', type: :view do
  let(:form_builder)  { double }
  let(:work)          { build(:public_generic_work, id: "99") }
  let(:featured_work) { FeaturedWork.create(work_id: "99", presenter: presenter) }
  let(:presenter)     { Hyrax::WorkShowPresenter.new(work, nil) }
  let(:page)          { rendered }

  before do
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
