# frozen_string_literal: true
RSpec.describe Hyrax::InstallIiifViewerService do
  let(:viewer) { :clover }
  let(:dest_root) { Pathname.new("/app/samvera/hyrax-engine/tmp") }
  let(:config) { dest_root.join('config', 'initializers', 'hyrax.rb').to_s }

  before do
    # Reset the file structure
    ["public", "app", "config"].each do |dir|
      FileUtils.rm_rf(dest_root.join(dir))
    end
    # Reset the viewer config
    Hyrax.config.iiif_av_viewer = Hyrax::Configuration.new.iiif_av_viewer
    FileUtils.mkdir_p("/app/samvera/hyrax-engine/tmp/config/initializers")
    File.open(config, 'w') do |f|
      f.write("Hyrax.config do |config|\n\nend")
    end
    # Mute the logging to stdout
    allow_any_instance_of(Thor::Shell::Basic).to receive(:say_status)
  end

  after do
    ["public", "app", "config"].each do |dir|
      FileUtils.rm_rf(dest_root.join(dir))
    end
  end

  describe 'self.install' do
    context 'when Hyrax.config.iiif_av_viewer was not set' do
      it 'copies files and configures the viewer' do
        expect do
          described_class.install(viewer)
          load config
        end
          .to change {
                Dir.glob("/app/samvera/hyrax-engine/tmp/public/clover/*")
              }.from([]).to(["/app/samvera/hyrax-engine/tmp/public/clover/clover.css",
                             "/app/samvera/hyrax-engine/tmp/public/clover/clover.html",
                             "/app/samvera/hyrax-engine/tmp/public/clover/clover.js"])
          .and change {
                 File.exist?(dest_root.join("app", "views", "hyrax", "base", "iiif_viewers", "_clover.html.erb"))
               }.from(false).to(true)
          .and change { Hyrax.config.iiif_av_viewer }.from(:universal_viewer).to(:clover)
      end
    end

    context 'when a different iiif_av_viewer was previously set' do
      before do
        File.open(config, 'w') do |f|
          f.write("Hyrax.config do |config|\n  config.iiif_av_viewer = :foo\nend")
        end
        load config
      end

      it 'copies files and configures the viewer' do
        expect do
          described_class.install(viewer)
          load config
        end
          .to change {
                Dir.glob("/app/samvera/hyrax-engine/tmp/public/clover/*")
              }.from([]).to(["/app/samvera/hyrax-engine/tmp/public/clover/clover.css",
                             "/app/samvera/hyrax-engine/tmp/public/clover/clover.html",
                             "/app/samvera/hyrax-engine/tmp/public/clover/clover.js"])
          .and change {
                 File.exist?(dest_root.join("app", "views", "hyrax", "base", "iiif_viewers", "_clover.html.erb"))
               }.from(false).to(true)
          .and change { Hyrax.config.iiif_av_viewer }.from(:foo).to(:clover)
      end
    end
  end

  describe 'self.remove' do
    context 'when Hyrax.config.iiif_av_viewer was not set' do
      before do
        described_class.install(viewer)
        load config
      end

      it 'removes files and resets the Hyrax initializer' do
        expect do
          described_class.remove(viewer)
          Hyrax.config.iiif_av_viewer = Hyrax::Configuration.new.iiif_av_viewer
          load config
        end
          .to change {
                Dir.glob("/app/samvera/hyrax-engine/tmp/public/clover/*")
              }.from(["/app/samvera/hyrax-engine/tmp/public/clover/clover.css",
                      "/app/samvera/hyrax-engine/tmp/public/clover/clover.html",
                      "/app/samvera/hyrax-engine/tmp/public/clover/clover.js"]).to([])
          .and change {
                 File.exist?(dest_root.join("app", "views", "hyrax", "base", "iiif_viewers", "_clover.html.erb"))
               }.from(true).to(false)
          .and change { Hyrax.config.iiif_av_viewer }.from(:clover).to(:universal_viewer)
      end
    end

    context 'when a different iiif_av_viewer was previously set' do
      before do
        File.open(config, 'w') do |f|
          f.write("Hyrax.config do |config|\n  config.iiif_av_viewer = :foo\nend")
        end
        described_class.install(viewer)
        load config
      end

      it 'removes files and resets the Hyrax initializer' do
        expect do
          described_class.remove(viewer)
          load config
        end
          .to change {
            Dir.glob("/app/samvera/hyrax-engine/tmp/public/clover/*")
          }.from(["/app/samvera/hyrax-engine/tmp/public/clover/clover.css",
                  "/app/samvera/hyrax-engine/tmp/public/clover/clover.html",
                  "/app/samvera/hyrax-engine/tmp/public/clover/clover.js"]).to([])
          .and change {
                 File.exist?(dest_root.join("app", "views", "hyrax", "base", "iiif_viewers", "_clover.html.erb"))
               }.from(true).to(false)
          .and change { Hyrax.config.iiif_av_viewer }.from(:clover).to(:foo)
      end
    end
  end
end
