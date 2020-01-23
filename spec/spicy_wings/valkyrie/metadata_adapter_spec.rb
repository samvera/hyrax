# frozen_string_literal: true
require 'spec_helper'
require 'valkyrie/specs/shared_specs'
require 'spicy_wings'

RSpec.describe SpicyWings::Valkyrie::MetadataAdapter do
  let(:adapter) { described_class.new }

  it_behaves_like "a Valkyrie::MetadataAdapter"
end
