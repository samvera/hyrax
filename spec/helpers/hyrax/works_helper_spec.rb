# frozen_string_literal: true

RSpec.describe Hyrax::WorksHelper, type: :helper do
  describe '#show_actions_for' do
    let(:presenter) { Hyrax::WorkShowPresenter.new(SolrDocument.new(id: 'abc123'), nil) }

    it 'contributes no actions of its own' do
      expect(helper.show_actions_for(presenter: presenter)).to eq []
    end

    it 'lets a downstream override add to the list' do
      helper.singleton_class.prepend(Module.new do
        def show_actions_for(presenter:)
          super + ['my_new_action']
        end
      end)

      expect(helper.show_actions_for(presenter: presenter)).to eq ['my_new_action']
    end
  end
end
