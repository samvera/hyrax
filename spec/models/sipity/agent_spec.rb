require 'spec_helper'

module Sipity
  RSpec.describe Agent, type: :model, no_clean: true do
    subject { described_class }
    its(:column_names) { is_expected.to include("proxy_for_id") }
    its(:column_names) { is_expected.to include("proxy_for_type") }
  end
end
