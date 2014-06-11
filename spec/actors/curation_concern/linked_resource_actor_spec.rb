require 'spec_helper'

describe CurationConcern::LinkedResourceActor do
  let(:user) { FactoryGirl.create(:user) }
  let(:parent) { FactoryGirl.create(:generic_work, user: user) }
  let(:link) { Worthwhile::LinkedResource.new.tap {|lr| lr.batch = parent } }
  let(:you_tube_link) { 'http://www.youtube.com/watch?v=oHg5SJYRHA0' }

  subject {
    CurationConcern::LinkedResourceActor.new(link, user, url: you_tube_link)
  }

  describe '#create' do
    describe 'success' do
      it 'adds a linked resource to the parent work' do
        expect(parent.linked_resources).to be_empty
        subject.create
        expect(parent.reload.linked_resources).to eq [link]
        link.reload
        expect(link.batch).to eq parent
        expect(link.url).to eq you_tube_link
      end
    end

    describe 'failure' do
      it 'returns false' do
        allow(link).to receive(:valid?).and_return(false)
        expect {
          expect(subject.create).to be false
        }.to_not change { Worthwhile::LinkedResource.count }
        expect(parent.reload.linked_resources).to eq []
      end
    end
  end

end
