RSpec.describe Hyrax::WorkBehavior do
  before do
    class EssentialWork < Valkyrie::Resource
      include Hyrax::WorkBehavior
    end
  end
  after do
    Object.send(:remove_const, :EssentialWork)
  end

  subject { EssentialWork.new }

  it 'mixes together all the goodness' do
    expect(subject.class.ancestors).to include(::Hyrax::HumanReadableType,
                                               Hyrax::Noid,
                                               Hyrax::Serializers,
                                               Hydra::WithDepositor,
                                               Solrizer::Common,
                                               Hyrax::Suppressible)
  end
  describe '#to_s' do
    it 'uses the provided titles' do
      subject.title = %w[Hello World]
      expect(subject.to_s).to include 'Hello'
      expect(subject.to_s).to include 'World'
    end
  end

  describe 'human_readable_type' do
    it 'has a default' do
      expect(subject.human_readable_type).to eq 'Essential Work'
    end
    it 'is settable (deprecated)' do
      allow(Deprecation).to receive(:warn)
      EssentialWork.human_readable_type = 'Custom Type'
      expect(subject.human_readable_type).to eq 'Custom Type'
    end
  end

  describe '#visibility=' do
    context "when set to public" do
      it "sets read_groups to public" do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        expect(subject.read_groups).to eq [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC]
      end
      it 'sets read_groups to blank if private' do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        expect(subject.read_groups).to eq []

        subject.read_groups = ['Valkyrax']
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PRIVATE
        expect(subject.read_groups).to eq ['Valkyrax']
      end
      it 'sets read_groups to authenticated if appropriate' do
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_AUTHENTICATED
        expect(subject.read_groups).to eq [Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_AUTHENTICATED]
      end
      it "doesn't override read_groups" do
        subject.read_groups += ['ValkyriePeople']
        subject.visibility = Hydra::AccessControls::AccessRight::VISIBILITY_TEXT_VALUE_PUBLIC
        expect(subject.read_groups).to contain_exactly Hydra::AccessControls::AccessRight::PERMISSION_TEXT_VALUE_PUBLIC, 'ValkyriePeople'
      end
    end
  end
end
