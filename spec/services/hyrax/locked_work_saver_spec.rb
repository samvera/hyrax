# frozen_string_literal: true

RSpec.describe Hyrax::LockedWorkSaver, valkyrie_adapter: :test_adapter do
  let(:work) { FactoryBot.valkyrie_create(:hyrax_work, :with_member_works) }
  let!(:read_copy) { work.dup }
  let!(:read_member_ids) { work.member_ids.dup }
  let(:first_id) { read_member_ids.first }
  let(:second_id) { read_member_ids.last }
  let(:other_member) { FactoryBot.valkyrie_create(:hyrax_work) }

  def save(changed: [])
    described_class.save(work: read_copy, read_member_ids: read_member_ids, changed: changed)
    Hyrax.query_service.find_by(id: work.id)
  end

  it 'saves the changes made to the work' do
    read_copy.title = ['A new title']

    expect(save.title).to eq ['A new title']
  end

  it 'keeps a member another process added after the work was read' do
    save_work_elsewhere(work.id) { |stored| stored.member_ids += [other_member.id] }

    expect(save.member_ids).to eq [first_id, second_id, other_member.id]
  end

  it 'drops a member another process removed after the work was read' do
    save_work_elsewhere(work.id) { |stored| stored.member_ids -= [first_id] }

    expect(save.member_ids).to eq [second_id]
  end

  it "keeps the caller's own member changes alongside another process's" do
    read_copy.member_ids = [second_id]
    save_work_elsewhere(work.id) { |stored| stored.member_ids += [other_member.id] }

    expect(save.member_ids).to eq [second_id, other_member.id]
  end

  it "keeps the caller's member order" do
    read_copy.member_ids = [second_id, first_id]

    expect(save.member_ids).to eq [second_id, first_id]
  end

  it 'keeps a member order another process saved when the caller did not change membership' do
    read_copy.title = ['A new title']
    save_work_elsewhere(work.id) { |stored| stored.member_ids = [second_id, first_id] }

    expect(save.member_ids).to eq [second_id, first_id]
  end

  it 'keeps a representative and thumbnail another process set' do
    save_work_elsewhere(work.id) do |stored|
      stored.representative_id = first_id
      stored.thumbnail_id = first_id
    end

    expect(save).to have_attributes(representative_id: first_id, thumbnail_id: first_id)
  end

  it 'keeps a representative the caller changed' do
    read_copy.representative_id = second_id
    save_work_elsewhere(work.id) { |stored| stored.representative_id = first_id }

    expect(save(changed: [:representative_id]).representative_id).to eq second_id
  end

  describe '.update' do
    it 'applies the change to the stored work, keeping what another process saved' do
      save_work_elsewhere(work.id) { |stored| stored.member_ids += [other_member.id] }

      described_class.update(id: work.id) { |stored| stored.member_ids -= [first_id] }

      expect(Hyrax.query_service.find_by(id: work.id).member_ids).to eq [second_id, other_member.id]
    end

    it 'reads the stored work while holding its lock' do
      locked_reads = []
      allow(Hyrax.query_service).to receive(:find_by).and_wrap_original do |original, id:|
        locked_reads << lock_held?(work.id) if id.to_s == work.id.to_s
        original.call(id: id)
      end

      described_class.update(id: work.id) { |stored| stored.title = ['A new title'] }

      expect(locked_reads).to include(true)
    end
  end

  it 'reads the stored work while holding its lock' do
    locked_reads = []
    allow(Hyrax.query_service).to receive(:find_by).and_wrap_original do |original, id:|
      locked_reads << lock_held?(work.id) if id.to_s == work.id.to_s
      original.call(id: id)
    end

    described_class.save(work: read_copy, read_member_ids: read_member_ids)

    expect(locked_reads).to include(true)
  end
end
