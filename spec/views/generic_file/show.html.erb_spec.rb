require 'spec_helper'

describe 'generic_files/show.html.erb' do
  describe 'usage statistics' do
    let(:generic_file) {
      content = double('content', versions: [])
      stub_model(GenericFile, noid: '123',
        depositor: 'bob',
        audit_stat: 1,
        content: content)
    }

    before do
      allow(controller).to receive(:current_user).and_return(stub_model(User))
      allow_any_instance_of(Ability).to receive(:can?).and_return(true)
      assign(:generic_file, generic_file)
      assign(:events, [])
    end

    context 'when enabled' do
      before do
        Sufia.config.usage_statistics = true
      end

      it 'appears on page' do
        render
        page = Capybara::Node::Simple.new(rendered)
        expect(page).to have_selector('a#stats', count: 1)
      end
    end

    context 'when disabled' do
      before do
        Sufia.config.usage_statistics = false
      end

      it 'does not appear on page' do
        render
        page = Capybara::Node::Simple.new(rendered)
        expect(page).to have_no_selector('a#stats')
      end
    end
  end
end
