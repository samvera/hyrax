# frozen_string_literal: true
RSpec.describe Hyrax::FileSetFormHelper do
  context 'with an ActiveFedora file set', :active_fedora do
    describe '#render_transcript_ids_field?' do
      subject { helper.render_transcript_ids_field?(file_set) }

      context 'without a parent' do
        let(:file_set) { FactoryBot.create(:file_set) }
        it { is_expected.to be_falsey }
      end

      context 'with a parent' do
        let(:file_set) { create(:work_with_one_file).file_sets.first }

        before do
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

    describe '#form_transcript_ids_select_for' do
      let(:user) { create(:admin) }
      let(:ability) { Ability.new(user) }
      subject { helper.form_transcript_ids_select_for(file_set) }

      before do
        allow(helper).to receive(:current_ability).and_return(ability)
      end

      let(:file_set) { create(:file_set) }
      let(:vtt) { create(:file_set, title: ["sample.vtt"], content: File.open(fixture_path + '/sample.vtt')) }

      before do
        work = create(:generic_work)
        work.ordered_members << file_set
        work.ordered_members << vtt
        work.save!
      end

      it { is_expected.to eq({ "sample.vtt" => vtt.id }) }
    end
  end

  context 'with a Valkyrie file set' do
    describe '#render_transcript_ids_field?' do
      subject { helper.render_transcript_ids_field?(file_set) }

      context 'without a parent' do
        let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
        it { is_expected.to be_falsey }
      end

      context 'with a parent' do
        let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set, :in_work) }
        subject { helper.render_transcript_ids_field?(file_set) }

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

    describe '#form_transcript_ids_select_for' do
      let(:user) { create(:admin) }
      let(:ability) { Ability.new(user) }
      subject { helper.form_transcript_ids_select_for(file_set) }

      before do
        allow(helper).to receive(:current_ability).and_return(ability)
      end

      let!(:work) { FactoryBot.valkyrie_create(:hyrax_work, members: [file_set, vtt_file_set]) }
      let(:file_set) { FactoryBot.valkyrie_create(:hyrax_file_set) }
      let(:vtt_file_set) do
        FactoryBot.valkyrie_create(:hyrax_file_set) do |file_set|
          Hyrax::ValkyrieUpload.file(filename: "sample.vtt",
                                     file_set: file_set,
                                     io: File.open(fixture_path + '/sample.vtt'))
        end
      end

      it { is_expected.to eq({ "sample.vtt" => vtt_file_set.id.to_s }) }
    end
  end
end
