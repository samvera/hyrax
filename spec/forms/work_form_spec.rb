require 'spec_helper'

describe Sufia::Forms::WorkForm do
  let(:form) { described_class.new(GenericWork.new, nil) }

  describe "#rendered_terms" do
    subject { form.rendered_terms }
    it { is_expected.not_to include(:visibilty, :visibility_during_embargo,
                                    :embargo_release_date, :visibility_after_embargo,
                                    :visibility_during_lease, :lease_expiration_date,
                                    :visibility_after_lease) }
  end
end
