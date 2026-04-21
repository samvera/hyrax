# frozen_string_literal: true
RSpec.describe Hyrax::FileSetFormHelper do
  context 'with an ActiveFedora file set', :active_fedora do
    describe '#render_transcript_ids_field?' do
      let(:file_set) { FactoryBot.build(:file_set) }
      subject { helper.render_transcript_ids_field?(file_set) }

      before do
        allow(file_set).to receive(:persisted?).and_return true
      end

      context 'without a parent' do
        it { is_expected.to be_falsey }
      end

      context 'with a parent' do
        before do
          assign(:parent, double)
          allow(file_set).to receive(:mime_type).and_return(mime_type)
        end

        context 'with a video file' do
          let(:mime_type) { 'video/mp4' }

          it { is_expected.to be_truthy }
        end

        context 'with an audio file' do
          let(:mime_type) { 'audio/mpeg' }

          it { is_expected.to be_truthy }
        end

        context 'with an image file' do
          let(:mime_type) { 'image/jpeg' }

          it { is_expected.to be_falsey }
        end
      end
    end

    describe '#transcript_ids_select_options' do
      let(:user) { create(:admin) }
      let(:ability) { Ability.new(user) }
      let(:file_set) { FactoryBot.create(:file_set) }
      let(:work) { FactoryBot.build(:generic_work) }
      let(:vtt) { create(:file_set, title: ["sample.vtt"], content: File.open(fixture_path + '/sample.vtt')) }

      subject { helper.transcript_ids_select_options }

      before do
        work.ordered_members << file_set
        work.ordered_members << vtt
        work.save!
        assign(:parent, work)
        allow(helper).to receive(:current_ability).and_return(ability)
      end

      it { is_expected.to eq({ "sample.vtt" => vtt.id }) }
    end
  end

  context 'with a Valkyrie file set' do
    describe '#render_transcript_ids_field?' do
      subject { helper.render_transcript_ids_field?(file_set) }

      before do
        allow(file_set).to receive(:persisted?).and_return true
      end

      context 'without a parent' do
        let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
        it { is_expected.to be_falsey }
      end

      context 'with a parent' do
        let(:file_set) { FactoryBot.build(:hyrax_file_set) }

        subject { helper.render_transcript_ids_field?(file_set) }

        before do
          assign(:parent, double)
        end

        context 'with a video file' do
          before do
            allow_any_instance_of(Hyrax::FileSetTypeService).to receive(:video?).and_return true
          end

          it { is_expected.to be_truthy }
        end

        context 'with an audio file' do
          before do
            allow_any_instance_of(Hyrax::FileSetTypeService).to receive(:audio?).and_return true
          end

          it { is_expected.to be_truthy }
        end

        context 'with an image file' do
          it { is_expected.to be_falsey }
        end
      end
    end

    describe '#transcript_ids_select_options' do
      let(:user) { create(:admin) }
      let(:ability) { Ability.new(user) }
      let(:work) { FactoryBot.valkyrie_create(:hyrax_work, members: [file_set, vtt_file_set]) }
      let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }

      let(:vtt_file_set) do
        FactoryBot.valkyrie_create(:hyrax_file_set,
                                   title: ['English Captions'])
      end

      let!(:vtt_file_metadata) do
        FactoryBot.valkyrie_create(:hyrax_file_metadata, :original_file, :with_file,
                        file_set: vtt_file_set,
                        original_filename: 'sample.vtt',
                        mime_type: 'text/vtt')
      end

      subject { helper.transcript_ids_select_options }

      before do
        allow(helper).to receive(:current_ability).and_return(ability)
        assign(:parent, work)
      end

      it { is_expected.to eq({ "English Captions" => vtt_file_set.id.to_s }) }
    end
  end
end
