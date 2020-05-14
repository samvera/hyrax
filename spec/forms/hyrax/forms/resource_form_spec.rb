# frozen_string_literal: true

RSpec.describe Hyrax::Forms::ResourceForm do
  subject(:form) { described_class.for(work) }
  let(:work)     { Hyrax::Work.new }

  describe '.required_fields=' do
    subject(:form) { form_class.new(work) }

    let(:form_class) do
      Class.new(Hyrax::Forms::ResourceForm(work.class)) do
        property :depositor
      end
    end

    it 'lists required fields' do
      expect(form_class.required_fields).to contain_exactly :title
    end

    it 'can add required fields' do
      expect { form_class.required_fields += [:depositor] }
        .to change { form.required?(:depositor) && form.required?(:title) }
        .to true
    end
  end

  describe '.model_class' do
    it 'is the class of the configured work' do
      expect(Hyrax::Forms::ResourceForm(work.class).model_class)
        .to eq work.class
    end
  end

  describe '#[]' do
    it 'supports access to work attributes' do
      expect(form[:title]).to eq work.title
    end

    it 'gives nil for unsupported attributes' do
      expect(form[:not_a_real_attribute]).to be_nil
    end
  end

  describe '#[]=' do
    it 'supports setting work attributes' do
      new_title = 'comet in moominland'

      expect { form[:title] = new_title }
        .to change { form[:title] }
        .to new_title
    end
  end

  describe '#agreement_accepted' do
    it { is_expected.to have_attributes(agreement_accepted: false) }

    it 'remains false when prepopulated' do
      expect { form.prepopulate! }
        .not_to change { form.agreement_accepted }
        .from false
    end

    context 'when the work already exists' do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work) }

      it 'prepopulates to true' do
        expect { form.prepopulate! }
          .to change { form.agreement_accepted }
          .to true
      end
    end
  end

  describe '#embargo_release_date' do
    context 'without an embargo' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.embargo_release_date }
          .from(nil)
      end
    end

    context 'with a work under embargo' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_embargo) }

      it 'defaults to the embargo date' do
        expect { form.prepopulate! }
          .to change { form.embargo_release_date }
          .to(work.embargo.embargo_release_date)
      end
    end
  end

  describe '#lease_expiration_date' do
    context 'without a lease' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.lease_expiration_date }
          .from(nil)
      end
    end

    context 'with a work under embargo' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_lease) }

      it 'defaults to the embargo date' do
        expect { form.prepopulate! }
          .to change { form.lease_expiration_date }
          .to(work.lease.lease_expiration_date)
      end
    end
  end

  describe '#model_class' do
    it 'is the class of the model' do
      expect(form.model_class).to eq work.class
    end
  end

  describe '#permissions' do
    it 'for a new object has empty permissions' do
      expect(form.permissions).to be_empty
    end

    it 'for a new object prepopulates with empty permissions' do
      expect { form.prepopulate! }
        .not_to change { form.permissions }
        .from(be_empty)
    end

    context 'with existing permissions' do
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :public) }

      it 'prepopulates with the work permissions' do
        expect { form.prepopulate! }
          .to change { form.permissions }
          .to contain_exactly(have_attributes(agent_name: 'group/public', access: :read))
      end
    end
  end

  describe '#human_readable_type' do
    it 'delegates to model' do
      expect(form.human_readable_type).to eq work.human_readable_type
    end
  end

  describe '#'

  describe '#required?' do
    subject(:form) { form_class.new(work) }

    let(:form_class) do
      Class.new(Hyrax::Forms::ResourceForm(work.class)) do
        property :non_required
      end
    end

    it 'is true for required fields' do
      expect(form.required?(:title)).to eq true
    end

    it 'is false for non-required fields' do
      expect(form.required?(:non_required)).to eq false
    end
  end

  describe '#visibility' do
    it 'can set visibility' do
      form.visibility = 'open'

      expect { form.sync }
        .to change { work.permission_manager.acl.permissions }
        .from(be_empty)
        .to contain_exactly(have_attributes(mode: :read, agent: 'group/public'))
    end
  end

  describe '#visibility_after_embargo' do
    context 'without an embargo' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.visibility_after_embargo }
          .from(nil)
      end
    end

    context 'with a work under embargo' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_embargo) }

      it 'defaults to the embargo visibility' do
        expect { form.prepopulate! }
          .to change { form.visibility_after_embargo }
          .from(nil)
          .to('open')
      end
    end
  end

  describe '#visibility_during_embargo' do
    context 'without an embargo' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.visibility_during_embargo }
          .from(nil)
      end
    end

    context 'with a work under embargo' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_embargo) }

      it 'defaults to the embargo visibility' do
        expect { form.prepopulate! }
          .to change { form.visibility_during_embargo }
          .from(nil)
          .to('authenticated')
      end
    end
  end

  describe '#visibility_after_lease' do
    context 'without a lease' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.visibility_after_lease }
          .from(nil)
      end
    end

    context 'with a work under lease' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_lease) }

      it 'defaults to the lease visibility' do
        expect { form.prepopulate! }
          .to change { form.visibility_after_lease }
          .from(nil)
          .to('authenticated')
      end
    end
  end

  describe '#visibility_during_lease' do
    context 'without a lease' do
      it 'is nil' do
        expect { form.prepopulate! }
          .not_to change { form.visibility_during_lease }
          .from(nil)
      end
    end

    context 'with a work under lease' do
      let(:work) { FactoryBot.build(:hyrax_work, :under_lease) }

      it 'defaults to the lease visibility' do
        expect { form.prepopulate! }
          .to change { form.visibility_during_lease }
          .from(nil)
          .to('open')
      end
    end
  end
end
