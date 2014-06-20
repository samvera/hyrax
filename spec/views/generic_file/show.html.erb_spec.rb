require 'spec_helper'

describe 'generic_files/show.html.erb' do
  let(:depositor) {
    stub_model(User,
      user_key: 'bob',
      twitter_handle: 'bot4lib')
  }

  let(:generic_file) {
    content = double('content', versions: [], mimeType: 'application/pdf')
    stub_model(GenericFile, noid: '123',
      depositor: depositor.user_key,
      audit_stat: 1,
      title: ['My Title'],
      description: ['Lorem ipsum lorem ipsum.'],
      tag: ['bacon', 'sausage', 'eggs'],
      rights: ['http://example.org/rights/1'],
      content: content)
  }

  before do
    allow(controller).to receive(:current_user).and_return(depositor)
    allow_any_instance_of(Ability).to receive(:can?).and_return(true)
    allow(User).to receive(:find_by_user_key).with(generic_file.depositor).and_return(depositor)
    allow(view).to receive(:blacklight_config).and_return(Blacklight::Configuration.new)
    assign(:generic_file, generic_file)
    assign(:events, [])
  end

  describe 'twitter cards' do
    before do
      allow(view).to receive(:on_the_dashboard?).and_return(false)
      assign(:notify_number, 0)
    end

    it 'appears in meta tags' do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
      meta_twitter_tags = Nokogiri::HTML(rendered).xpath("//meta")
      expect(meta_twitter_tags.count).to eq(15)
    end

    it 'displays twitter:card' do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='twitter:card']")
      expect(tag.attribute('content').value).to eq('product')
    end

    it 'displays twitter:site' do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='twitter:site']")
      expect(tag.attribute('content').value).to eq('@HydraSphere')
    end

    it 'displays twitter:creator' do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='twitter:creator']")
      expect(tag.attribute('content').value).to eq('@bot4lib')
    end

    it 'displays og:site_name' do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
      tag = Nokogiri::HTML(rendered).xpath("//meta[@property='og:site_name']")
      expect(tag.attribute('content').value).to eq('Sufia')
    end

    it 'displays og:type' do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
      tag = Nokogiri::HTML(rendered).xpath("//meta[@property='og:type']")
      expect(tag.attribute('content').value).to eq('object')
    end

    it 'displays og:title' do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
      tag = Nokogiri::HTML(rendered).xpath("//meta[@property='og:title']")
      expect(tag.attribute('content').value).to eq('My Title')
    end

    it 'displays og:description' do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
      tag = Nokogiri::HTML(rendered).xpath("//meta[@property='og:description']")
      expect(tag.attribute('content').value).to eq('Lorem ipsum lorem ipsum.')
    end

    it 'displays og:image' do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
      tag = Nokogiri::HTML(rendered).xpath("//meta[@property='og:image']")
      expect(tag.attribute('content').value).to eq('http://test.host/downloads/123?datastream_id=thumbnail')
    end

    it 'displays og:url' do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
      tag = Nokogiri::HTML(rendered).xpath("//meta[@property='og:url']")
      expect(tag.attribute('content').value).to eq('http://test.host/files/123')
    end

    it 'displays twitter:data1' do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='twitter:data1']")
      expect(tag.attribute('content').value).to eq('bacon, sausage, eggs')
    end

    it 'displays twitter:label1' do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='twitter:label1']")
      expect(tag.attribute('content').value).to eq('Keywords')
    end

    it 'displays twitter:data2' do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='twitter:data2']")
      expect(tag.attribute('content').value).to eq('http://example.org/rights/1')
    end

    it 'displays twitter:label2' do
      render template: 'generic_files/show.html.erb', layout: 'layouts/sufia-one-column'
      tag = Nokogiri::HTML(rendered).xpath("//meta[@name='twitter:label2']")
      expect(tag.attribute('content').value).to eq('Rights')
    end
  end

  describe 'analytics' do

    context 'when enabled' do
      before do
        Sufia.config.analytics = true
      end

      it 'appears on page' do
        render
        page = Capybara::Node::Simple.new(rendered)
        expect(page).to have_selector('a#stats', count: 1)
      end
    end

    context 'when disabled' do
      before do
        Sufia.config.analytics = false
      end

      it 'does not appear on page' do
        render
        page = Capybara::Node::Simple.new(rendered)
        expect(page).to have_no_selector('a#stats')
      end
    end
  end

  describe 'featured' do

    context "public file" do
      before do
        allow(generic_file).to receive(:public?).and_return(true)
      end

      it "shows featured feature link for public file" do
        render
        page = Capybara::Node::Simple.new(rendered)
        expect(page).to have_selector('a[data-behavior="feature"]', count: 1)
      end
    end

    context "non public file" do
      before do
        allow(generic_file).to receive(:public?).and_return(false)
      end

      it "does not show feature link for non public file" do
        render
        page = Capybara::Node::Simple.new(rendered)
        expect(page).to have_no_selector('a[data-behavior="feature"]', count: 1)
      end
    end
  end
end
