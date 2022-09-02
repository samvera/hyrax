# frozen_string_literal: true

# Generated via
#  `rails generate hyrax:work_resource GenericWork`
require 'rails_helper'
require 'hyrax/specs/shared_specs/hydra_works'

RSpec.describe GenericWork do
  subject(:work) { described_class.new }
  let(:resource) { work }

  it_behaves_like 'a Hyrax::Work'
end
