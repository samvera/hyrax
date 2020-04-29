# frozen_string_literal: true

RSpec.describe Hyrax::Forms::ResourceForm do
  subject(:form)   { described_class.for(work) }
  let(:work)       { Hyrax::Work.new }

  describe '.required_fields=' do
    subject(:form) { form_class.new(work) }

    let(:form_class) do
      Class.new(Hyrax::Forms::ResourceForm(work.class)) do
        self.required_fields = [:title]
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

  describe '#required?' do
    it 'is false for non-required fields' do
      expect(form.required?(:title)).to eq false
    end

    context 'when some fields are required' do
      subject(:form) { form_class.new(work) }

      let(:form_class) do
        Class.new(Hyrax::Forms::ResourceForm(work.class)) do
          self.required_fields = [:title]
        end
      end

      it 'is true for required fields' do
        expect(form.required?(:title)).to eq true
      end

      it 'is false for non-required fields' do
        expect(form.required?(:depositor)).to eq false
      end
    end
  end
end
