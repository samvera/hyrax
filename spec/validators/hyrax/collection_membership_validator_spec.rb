# frozen_string_literal: true

RSpec.describe Hyrax::CollectionMembershipValidator do
  subject(:validator) { described_class.new }
  let(:work) { FactoryBot.build(:hyrax_work, :as_collection_member) }
  let(:form) { Hyrax::Forms::ResourceForm(Monograph).new(work) }

  describe '#validate' do
    it 'is valid' do
      expect { validator.validate(form) }
        .not_to change { form.errors }
        .from be_empty
    end

    it 'does not change existing collections' do
      expect { validator.validate(form) }
        .not_to change { form.member_of_collection_ids }
    end
  end
end
