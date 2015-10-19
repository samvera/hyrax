require 'curation_concerns/callbacks'

describe CurationConcerns::Callbacks do
  context 'when included in a class,' do
    before do
      class TestClass
        include CurationConcerns::Callbacks
      end
    end

    after do
      Object.send(:remove_const, :TestClass)
    end

    describe '.callback' do
      it 'returns an instance of Callbacks::Registry' do
        expect(TestClass.callback).to be_a CurationConcerns::Callbacks::Registry
      end
    end

    describe '#callback' do
      it 'is an instance method shortcut to the class method of the same name' do
        expect(TestClass.new.callback).to eq TestClass.callback
      end
    end
  end
end
