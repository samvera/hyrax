# frozen_string_literal: true
RSpec.describe Hyrax::DropdownFacetFieldComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:facet_field) do
    instance_double(Blacklight::FacetFieldPresenter,
                    key: 'visibility_ssi',
                    label: 'Visibility',
                    modal_path: nil,
                    in_modal?: false,
                    active?: false,
                    collapsed?: false,
                    paginator: instance_double(Blacklight::FacetPaginator, items: []))
  end

  let(:component) { described_class.new(facet_field: facet_field) }

  before do
    # Blacklight skips facets with no values; the wrapper markup is what is under test.
    allow(component).to receive(:render?).and_return(true)
    render_inline(component)
  end

  # A .btn-group squares the toggle's left corners because the legend is its first child.
  it 'wraps the toggle in a dropdown, not a button group' do
    expect(page).to have_css('fieldset.dropdown > button.dropdown-toggle', text: 'Visibility')
    expect(page).not_to have_css('fieldset.btn-group')
  end
end
