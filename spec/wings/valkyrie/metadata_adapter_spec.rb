# frozen_string_literal: true

return if Hyrax.config.disable_wings

require 'spec_helper'
require 'valkyrie/specs/shared_specs'
require 'wings'

RSpec.describe Wings::Valkyrie::MetadataAdapter, :active_fedora do
  let(:adapter) { described_class.new }

  it_behaves_like "a Valkyrie::MetadataAdapter"
end
