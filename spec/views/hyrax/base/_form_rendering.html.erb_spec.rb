RSpec.describe 'hyrax/base/_form_rendering.html.erb', type: :view do
  let(:ability) { double }
  let(:work) { create(:work_with_one_file) }
  let(:form) do
    Hyrax::GenericWorkForm.new(work, ability, controller)
  end

  let(:page) do
    view.simple_form_for form do |f|
      render 'hyrax/base/form_rendering', f: f
    end
    Capybara::Node::Simple.new(rendered)
  end

  it 'has a rendering_ids field' do
    expect(page).to have_selector("select#generic_work_rendering_ids", count: 1)
  end
end
