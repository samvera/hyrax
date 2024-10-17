# frozen_string_literal: true

RSpec.describe 'hyrax/admin/admin_sets/_show_document_list.html.erb', type: :view do
  let(:documents) { ["Hello", "World"] }

  before do
    stub_template('hyrax/admin/admin_sets/_show_document_list_row.html.erb' => "<%= show_document_list_row %>")
  end

  it "renders rows of works" do
    render('hyrax/admin/admin_sets/show_document_list', documents: documents)
    expect(rendered).to have_css('tbody', text: documents.join)
  end
end
