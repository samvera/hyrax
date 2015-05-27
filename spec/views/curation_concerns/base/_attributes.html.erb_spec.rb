require 'spec_helper'

describe 'curation_concerns/base/_attributes.html.erb' do

  let(:creator)     { 'Bilbo' }
  let(:contributor) { 'Frodo' }
  let(:subject)     { 'history' }

  let(:curation_concern) { double(creator: [creator],
                                  contributor: [contributor],
                                  subject: [subject]) }

  before do
    allow(view).to receive(:dom_class) { '' }
    allow(view).to receive(:permission_badge_for) { '' }

    render partial: 'attributes', locals: { curation_concern: curation_concern }
  end

  it 'has links to search for other objects with the same metadata' do
    expect(rendered).to have_link(creator, href: catalog_index_path(search_field: 'creator', q: creator))
    expect(rendered).to have_link(contributor, href: catalog_index_path(search_field: 'contributor', q: contributor))
    expect(rendered).to have_link(subject, href: catalog_index_path(search_field: 'subject', q: subject))
  end
end
