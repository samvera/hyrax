module Sipity
  RSpec.describe Agent, type: :model do
    subject { described_class }

    its(:column_names) { is_expected.to include("proxy_for_id") }
    its(:column_names) { is_expected.to include("proxy_for_type") }
  end
end
