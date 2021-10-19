# frozen_string_literal: true

require 'spec_helper'
require 'hyrax/specs/shared_specs/hydra_works'

RSpec.describe Hyrax::AdministrativeSet do
  it_behaves_like 'a Hyrax::AdministrativeSet'

  it do
    subject.collection_type_gid
  end
end
