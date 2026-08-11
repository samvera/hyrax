# frozen_string_literal: true
RSpec.describe Hyrax::CitationsBehaviors::PublicationBehavior do
  subject(:behavior) { Class.new { include Hyrax::CitationsBehaviors::PublicationBehavior }.new }

  let(:work) do
    double('presenter',
           based_near_label: Array(place),
           publisher: Array(publisher),
           date_created: Array(date_created))
  end
  let(:place)        { nil }
  let(:publisher)    { nil }
  let(:date_created) { nil }

  describe '#setup_pub_info' do
    context 'with a publisher and no place of publication' do
      let(:publisher) { 'Scripps Institution of Oceanography' }

      it 'returns just the publisher' do
        expect(behavior.setup_pub_info(work)).to eq('Scripps Institution of Oceanography')
      end
    end

    context 'with both a place and a publisher' do
      let(:place)     { 'La Jolla' }
      let(:publisher) { 'Scripps Institution of Oceanography' }

      it 'returns the place and publisher separated by a colon' do
        expect(behavior.setup_pub_info(work)).to eq('La Jolla: Scripps Institution of Oceanography')
      end
    end

    context 'with a place and no publisher' do
      let(:place) { 'La Jolla' }

      it 'returns just the place' do
        expect(behavior.setup_pub_info(work)).to eq('La Jolla')
      end
    end

    context 'with a blank publisher' do
      let(:publisher) { '' }

      it 'returns nothing' do
        expect(behavior.setup_pub_info(work)).to be_nil
      end
    end

    context 'with neither a place nor a publisher' do
      it 'returns nothing' do
        expect(behavior.setup_pub_info(work)).to be_nil
      end
    end

    context 'when including the date' do
      let(:date_created) { '1960' }

      context 'with a publisher' do
        let(:publisher) { 'Scripps Institution of Oceanography' }

        it 'returns the publisher and the date' do
          expect(behavior.setup_pub_info(work, true)).to eq('Scripps Institution of Oceanography, 1960')
        end
      end

      context 'with no place or publisher' do
        it 'returns just the date' do
          expect(behavior.setup_pub_info(work, true)).to eq('1960')
        end
      end

      context 'when the date has no digits' do
        let(:date_created) { 'circa' }

        it 'returns nothing' do
          expect(behavior.setup_pub_info(work, true)).to be_nil
        end
      end
    end
  end
end
