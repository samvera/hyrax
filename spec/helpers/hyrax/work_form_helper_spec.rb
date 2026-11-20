# frozen_string_literal: true

require 'hyrax/specs/shared_specs'

RSpec.describe Hyrax::WorkFormHelper do
  describe '.form_tabs_for' do
    context 'with a change set style form' do
      let(:work) { build(:hyrax_work) }
      let(:form) { Hyrax::Forms::ResourceForm.for(resource: work) }

      it 'returns a default tab list' do
        expect(form_tabs_for(form: form)).to eq ["metadata", "files", "relationships"]
      end
    end

    context 'with a legacy GenericWork form', :active_fedora do
      let(:work) { stub_model(GenericWork, id: '456') }
      let(:ability) { double }
      let(:form) { Hyrax::GenericWorkForm.new(work, ability, controller) }

      it 'returns a default tab list' do
        expect(form_tabs_for(form: form)).to eq ["metadata", "files", "relationships"]
      end
    end

    context 'with a batch upload form', :active_fedora do
      let(:work) { stub_model(GenericWork, id: '456') }
      let(:ability) { double }
      let(:form) { Hyrax::Forms::BatchUploadForm.new(work, ability, controller) }

      it 'returns an alternate tab ordering' do
        expect(form_tabs_for(form: form)).to eq ["files", "metadata", "relationships"]
      end
    end
  end

  describe '.form_tab_label_for' do
    let(:form) { double('form') }
    let(:tab) { 'metadata' }

    it 'returns the label' do
      expect(form_tab_label_for(form: form, tab: tab)).to eq "Descriptions"
    end
  end

  describe '.form_progress_sections_for' do
    context 'with a change set style form' do
      let(:work) { build(:hyrax_work) }
      let(:form) { Hyrax::Forms::ResourceForm.for(resource: work) }

      it 'returns an empty list' do
        expect(form_progress_sections_for(form: form)).to eq []
      end
    end

    context 'with a legacy GenericWork form', :active_fedora do
      let(:work) { stub_model(GenericWork, id: '456') }
      let(:ability) { double }
      let(:form) { Hyrax::GenericWorkForm.new(work, ability, controller) }

      it 'returns an empty list' do
        expect(form_progress_sections_for(form: form)).to eq []
      end
    end

    context 'with a batch upload form', :active_fedora do
      let(:work) { stub_model(GenericWork, id: '456') }
      let(:ability) { double }
      let(:form) { Hyrax::Forms::BatchUploadForm.new(work, ability, controller) }

      it 'returns an empty list' do
        expect(form_progress_sections_for(form: form)).to eq []
      end
    end
  end

  describe '.form_file_set_select_for' do
    context 'with a ChangeSet form' do
      let(:form) { Valkyrie::ChangeSet.new(work) }
      let(:work) { FactoryBot.build(:hyrax_work) }

      it 'gives no options' do
        expect(form_file_set_select_for(parent: form)).to be_empty
      end
    end

    context 'with a ChangeSet-style ResourceForm' do
      let(:form) { Hyrax::Forms::ResourceForm.for(resource: work) }
      let(:work) { FactoryBot.build(:hyrax_work) }

      it 'gives no options' do
        expect(form_file_set_select_for(parent: form)).to be_empty
      end

      context 'with file_set members', index_adapter: :solr_index, valkyrie_adapter: :test_adapter do
        let(:work) { FactoryBot.build(:hyrax_work, member_ids: file_sets.map(&:id)) }

        let(:file_sets) do
          [FactoryBot.valkyrie_create(:hyrax_file_set, title: 'moominpapa.jpg'),
           FactoryBot.valkyrie_create(:hyrax_file_set, title: 'snorkmaiden.jpg')]
        end

        before { file_sets.each { |fs| Hyrax.index_adapter.save(resource: fs) } }

        it 'gives label/id pairs' do
          expect(form_file_set_select_for(parent: form))
            .to include(['moominpapa.jpg', an_instance_of(String)],
                        ['snorkmaiden.jpg', an_instance_of(String)])
        end

        context 'and work members' do
          let(:work) { FactoryBot.build(:hyrax_work, member_ids: member_ids) }
          let(:member_ids) { file_sets.map(&:id) + [member_work.id] }
          let(:member_work) { FactoryBot.build(:hyrax_work) }

          it 'gives label/id pairs for file_sets only' do
            expect(form_file_set_select_for(parent: form).map(&:last))
              .not_to include member_work.id.to_s
          end

          context 'and the child works have file sets' do
            let(:member_work) do
              FactoryBot.valkyrie_create(:hyrax_work, title: ['Child Work'], member_ids: [child_file_set.id])
            end
            let(:child_file_set) { FactoryBot.valkyrie_create(:hyrax_file_set, title: 'moomintroll.jpg') }

            before do
              Hyrax.index_adapter.save(resource: child_file_set)
              Hyrax.index_adapter.save(resource: member_work)
            end

            it 'includes file sets from child works, labels qualified by the owning work' do
              expect(form_file_set_select_for(parent: form))
                .to include(['moominpapa.jpg', an_instance_of(String)],
                            ['moomintroll.jpg (Child Work)', child_file_set.id.to_s])
            end

            context 'and membership contains a cycle' do
              let(:work) { FactoryBot.valkyrie_create(:hyrax_work, member_ids: member_ids) }
              let(:member_work) do
                FactoryBot.valkyrie_create(:hyrax_work, title: ['Child Work'], member_ids: [child_file_set.id])
              end

              before do
                member_work.member_ids += [work.id]
                Hyrax.persister.save(resource: member_work)
                Hyrax.index_adapter.save(resource: member_work)
                Hyrax.index_adapter.save(resource: work)
              end

              it 'terminates and still lists the descendant file sets' do
                expect(form_file_set_select_for(parent: form))
                  .to include(['moomintroll.jpg (Child Work)', child_file_set.id.to_s])
              end
            end
          end
        end
      end
    end

    context 'with a legacy GenericWork form', :active_fedora do
      let(:work) { stub_model(GenericWork, id: '456', member_ids: file_set_ids) }
      let(:ability) { double }
      let(:file_set_ids) { [] }
      let(:form) { Hyrax::GenericWorkForm.new(work, ability, controller) }

      it 'returns an empty hash' do
        expect(form_file_set_select_for(parent: form)).to eq({})
      end

      context 'with file_set members' do
        let(:file_set_ids) { file_sets.map(&:id) }

        let(:file_sets) do
          [FactoryBot.create(:file_set, label: 'moomin.jpg'),
           FactoryBot.create(:file_set, label: 'snork.jpg')]
        end

        it 'gives labels => ids' do
          expect(form_file_set_select_for(parent: form))
            .to include('moomin.jpg' => an_instance_of(String),
                        'snork.jpg' => an_instance_of(String))
        end
      end
    end
  end
end
