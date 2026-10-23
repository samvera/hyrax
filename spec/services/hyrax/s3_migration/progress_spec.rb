# frozen_string_literal: true

RSpec.describe Hyrax::S3Migration::Progress do
  let(:out) { StringIO.new }
  let(:times) { [0.0, 10.0, 20.0, 3725.0] }
  let(:clock) { -> { times.shift || 3725.0 } }

  def build(**options)
    described_class.new(every: 2, out:, clock:, **options)
  end

  it 'prints nothing until the interval is reached' do
    build.tick

    expect(out.string).to be_empty
  end

  it 'prints the count, rate and elapsed time at each interval' do
    progress = build
    2.times { progress.tick }

    expect(out.string).to eq "  ... 2 examined (0.2/s, 0:10 elapsed)\n"
  end

  context 'with a long run' do
    let(:times) { [0.0, 3725.0] }

    it 'shows hours' do
      progress = build
      2.times { progress.tick }

      expect(out.string).to include('1:02:05 elapsed')
    end
  end

  it 'appends the running detail when given' do
    progress = build(detail: -> { 'would_migrate: 2' })
    2.times { progress.tick }

    expect(out.string).to include('  would_migrate: 2')
  end

  it 'is silent when the interval is zero' do
    progress = described_class.new(every: 0, out:)
    5.times { progress.tick }

    expect(out.string).to be_empty
  end

  it 'defaults to every 500 items, configurable with PROGRESS_EVERY' do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('PROGRESS_EVERY', 500).and_return('3')
    progress = described_class.new(out:)
    3.times { progress.tick }

    expect(out.string).to include('3 examined')
  end
end
