# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'building a IIIF Manifest', :aggregate_failures do
  let(:work) { valkyrie_create(:comet_in_moominland, :public, description: ['a novel about moomins'], members: children) }
  let(:children) { valkyrie_create_list(:monograph, 1, members: file_sets) + file_sets }
  let(:user) { create(:admin) }
  let(:uploaded_file) { FactoryBot.create(:uploaded_file, file: file_fixture('world.png').open) }
  let(:file_sets) do
    valkyrie_create_list(:hyrax_file_set, 1) .map do |file_set|
      valkyrie_create(:hyrax_file_metadata, :original_file, :image, :with_file, original_filename: 'world.png', file_set: file_set, file: uploaded_file)
      Hyrax.persister.save(resource: file_set)
    end
  end

  it 'gets a full manifest for the work' do
    sign_in user # admins have access to public and private resources
    visit "/concern/generic_works/#{work.id}/manifest"
    manifest_json = JSON.parse(page.body)

    expect(manifest_json['label']).to eq 'Comet in Moominland'
    expect(manifest_json['description']).to eq 'a novel about moomins'

    expect(manifest_json['sequences'].size).to eq 1

    sequence = manifest_json['sequences'].first

    # 1 file set, plus child work with 1 file set = 2 canvases (i.e. images)
    expect(sequence['canvases'].count).to eq 2
  end

  context 'with a user missing read permissions on children' do
    let(:children) { file_sets }

    it 'generates a bare manifest' do
      logout # unauthenticated users do not have access to private resources
      visit "/concern/generic_works/#{work.id}/manifest"
      manifest_json = JSON.parse(page.body)

      expect(manifest_json['label']).to eq 'Comet in Moominland'
      expect(manifest_json).not_to have_key 'sequences'
    end
  end
end
