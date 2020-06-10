# frozen_string_literal: true
module Hyrax
  RSpec.describe Microdata do
    let(:yml_path) { File.join(fixture_path, 'config', 'schema_org.yml') }
    let(:yml_path_secondary) { File.join(fixture_path, 'config', 'schema_org_second.yml') }

    before do
      described_class.load_paths = yml_path
    end

    after do
      # Need to reset as this is an instance variable
      described_class.clear_load_paths!
    end

    describe '.load_paths' do
      subject { described_class.load_paths }

      it { is_expected.to be_a(Array) }
      it 'can be appended to' do
        expect { subject << yml_path_secondary }.to change { described_class.load_paths.size }.by(1)
      end
    end
    describe '.load_paths=' do
      it 'replaces the existing' do
        expect do
          described_class.load_paths = yml_path_secondary
        end.to change { described_class.load_paths }.to([yml_path_secondary])
      end
    end
    describe '.fetch' do
      describe 'with one file in the load path' do
        describe 'with a default' do
          describe 'and a miss on the key' do
            it 'will be the given default value' do
              expect(described_class.fetch('going.to.miss', default: "and a miss")).to eq('and a miss')
            end
          end
          describe 'and hit on the key' do
            subject { described_class.fetch('name.value') }

            it 'will be the registered value' do
              expect(subject).to eq('firstName')
            end
          end
        end
        describe 'without a default' do
          describe 'and a miss on the key' do
            subject { described_class.fetch('going.to.miss') }

            it { is_expected.to be_nil }
          end
          describe 'and hit on the key' do
            subject { described_class.fetch('name.value') }

            it 'will be the registered value' do
              expect(subject).to eq('firstName')
            end
          end
        end
      end
      describe 'with multiple files in the load path' do
        before do
          described_class.load_paths = [yml_path, yml_path_secondary]
        end
        describe 'and a miss on the key' do
          it 'will be the given default value' do
            expect(described_class.fetch('going.to.miss', default: "and a miss")).to eq('and a miss')
          end
        end
        describe 'and what would be a hit on the first and second loaded file' do
          subject { described_class.fetch('name.value') }

          it 'will be the second value loaded' do
            expect(subject).to eq('secondFirstName')
          end
        end
        describe 'and a hit on the first loaded file but not the second' do
          subject { described_class.fetch('first_only.value') }

          it 'will be the first loaded value' do
            expect(subject).to eq('iAmTheFirstOnly')
          end
        end
        describe 'and a hit on the second loaded file but not the first' do
          subject { described_class.fetch('second_only.value') }

          it 'will be the first loaded value' do
            expect(subject).to eq('iAmTheSecondOnly')
          end
        end
      end
    end
  end
end
