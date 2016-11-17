require 'spec_helper'

describe WelcomeController do
  describe '#index' do
    before { get :index }

    it 'displays the welcome page' do
      expect(response).to be_success
      expect(response).to render_template :index
    end
  end
end
