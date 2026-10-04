# frozen_string_literal: true
RSpec.describe "batch edit routes", type: :routing do
  routes { Hyrax::Engine.routes }

  it 'routes the dashboard bulk delete to destroy_collection' do
    expect(delete: '/batch_edits').to route_to(controller: 'hyrax/batch_edits', action: 'destroy_collection')
  end
end
