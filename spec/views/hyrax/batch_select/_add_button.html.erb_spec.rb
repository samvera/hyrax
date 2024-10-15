# frozen_string_literal: true

RSpec.describe 'hyrax/batch_select/_add_button.html.erb', type: :view do
  let(:document) { double(id: 123) }
  before do
    render 'hyrax/batch_select/add_button', document: document
  end

  it 'renders a checkbox named "batch_document_ids[]"' do
    # See ./app/controllers/concerns/hyrax/collections/accepts_batches.rb
    # for how we expect the input fields to have a name "batch_document_ids[]"
    expect(rendered).to have_selector(%([data-behavior="batch-add-button"] .batch_document_selector#batch_document_#{document.id}[name="batch_document_ids[]"][value=#{document.id}][type=checkbox]))
  end
end
