# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'building a IIIF Manifest', :clean_repo do
  let(:work) { valkyrie_create(:comet_in_moominland, :public, description: ['a novel about moomins']) }
  let(:user) { create(:admin) }
  let(:file_path) { fixture_path + '/world.png' }
  let(:original_file) { File.open(file_path) }
  let(:uploaded_file) { FactoryBot.create(:uploaded_file, file: original_file) }
  let(:persister) { Hyrax.persister }

  before do
    2.times { build_a_child_work }
    12.times { build_a_file_set_with_an_image }
    persister.save(resource: work)
    Hyrax.index_adapter.save(resource: work)

    sign_in user
  end

  it 'gets a full manifest for the work' do
    manifest_json = load_manifest_check_standards
    expect(manifest_json['sequences']).not_to be_empty

    sequence = manifest_json['sequences'].first

    # 12 file sets, plus 2 child works with 2 file sets each
    expect(sequence['canvases'].count).to eq 16
  end

  context 'with a user missing read permissions on children' do
    let(:user) { create(:user) }

    before do
      work.permission_manager.read_users = [user]
      persister.save(resource: work)
    end

    it 'generates a bare manifest' do
      manifest_json = load_manifest_check_standards
      expect(manifest_json).not_to have_key 'sequences'
    end
  end

  def build_a_child_work
    first_file_set = valkyrie_create(:hyrax_file_set)
    second_file_set = valkyrie_create(:hyrax_file_set)
    valkyrie_create(:hyrax_file_metadata, :original_file, :image, :with_file, original_filename: 'world.png', file_set: first_file_set, file: uploaded_file)
    valkyrie_create(:hyrax_file_metadata, :original_file, :image, :with_file, original_filename: 'world.png', file_set: second_file_set, file: uploaded_file)
    [first_file_set, second_file_set].each { |fs| persister.save(resource: fs) }
    child_work = valkyrie_create(:monograph,
                                 members: [first_file_set, second_file_set],
                                 title: ['supplemental object'],
                                 creator: ['Author, Samantha'],
                                 description: ['supplemental materials'])
    work.member_ids += [child_work.id]
  end

  def build_a_file_set_with_an_image
    file_set = valkyrie_create(:hyrax_file_set, title: ['page n'], creator: ['Jansson, Tove'], description: ['the nth page'])
    valkyrie_create(:hyrax_file_metadata, :original_file, :image, :with_file, original_filename: 'world.png', file_set: file_set, file: uploaded_file)
    persister.save(resource: file_set)
    work.member_ids += [file_set.id]
  end

  def load_manifest_check_standards
    visit "/concern/generic_works/#{work.id}/manifest"

    # maybe validate this with https://github.com/IIIF/presentation-validator/blob/master/schema/iiif_3_0.json ?
    manifest_json = JSON.parse(page.body)

    expect(manifest_json['label']).to eq 'Comet in Moominland'
    expect(manifest_json['description']).to contain_exactly('a novel about moomins')
    manifest_json
  end
end
