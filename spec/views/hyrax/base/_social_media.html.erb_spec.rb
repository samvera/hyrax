require 'spec_helper'

describe 'hyrax/base/_social_media.html.erb', type: :view do
  let(:url) { 'http://example.com/' }
  let(:title) { 'Example' }
  let(:page) do
    render partial: 'hyrax/base/social_media', locals: { share_url: url, page_title: title }
    Capybara::Node::Simple.new(rendered)
  end

  it 'renders various social media share links' do
    expect(page).to have_selector '.resp-sharing-button__link'
    expect(page).to have_link '', href: 'https://facebook.com/sharer/sharer.php?u=http%3A%2F%2Fexample.com%2F'
    expect(page).to have_link '', href: 'https://twitter.com/intent/tweet/?text=Example&url=http%3A%2F%2Fexample.com%2F'
    expect(page).to have_link '', href: 'https://plus.google.com/share?url=http%3A%2F%2Fexample.com%2F'
    expect(page).to have_link '', href: 'https://www.tumblr.com/widgets/share/tool?canonicalUrl=http%3A%2F%2Fexample.com%2F&posttype=link&shareSource=tumblr_share_button'
  end
end
