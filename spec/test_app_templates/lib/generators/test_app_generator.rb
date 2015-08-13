require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root "../../spec/test_app_templates"

  def install_engine
    generate 'curation_concerns:install'
  end

  def run_migrations
    rake "db:migrate"
  end

  def generate_generic_work
    generate 'curation_concerns:work GenericWork'
  end

  def remove_generic_work_specs
    remove_file 'spec/models/generic_work_spec.rb'
    remove_file 'spec/controllers/curation_concerns/generic_works_controller_spec.rb'
    remove_file 'spec/actors/curation_concerns/generic_work_actor_spec.rb'
  end

  def enable_av_transcoding
    file_path = "app/models/generic_file.rb"
      inject_into_file file_path, after: /include ::CurationConcerns::GenericFileBehavior/ do
      %q(
  directly_contains_one :ogg, through: :files, type: ::RDF::URI("http://pcdm.org/use#ServiceFile"), class_name: "Hydra::PCDM::File"
  directly_contains_one :mp3, through: :files, type: ::RDF::URI("http://pcdm.org/use#File"), class_name: "Hydra::PCDM::File"    
  directly_contains_one :mp4, through: :files, type: ::RDF::URI("http://pcdm.org/use#ServiceFile"), class_name: "Hydra::PCDM::File"
  directly_contains_one :webm, through: :files, type: ::RDF::URI("http://pcdm.org/use#File"), class_name: "Hydra::PCDM::File"


  # This was taken directly from Sufia's GenericFile::Derivative.
  makes_derivatives do |obj|
    case obj.original_file.mime_type
    when *pdf_mime_types
      obj.transform_file :original_file, thumbnail: { format: 'jpg', size: '338x493' }
    when *office_document_mime_types
      obj.transform_file :original_file, { thumbnail: { format: 'jpg', size: '200x150>' } }, processor: :document
     when *audio_mime_types
      obj.transform_file :original_file, { mp3: { format: 'mp3' }, ogg: { format: 'ogg' } }, processor: :audio
    when *video_mime_types
      obj.transform_file :original_file, { webm: { format: 'webm' }, mp4: { format: 'mp4' }, thumbnail: { format: 'jpg' } }, processor: :video
    when *image_mime_types
      obj.transform_file :original_file, thumbnail: { format: 'jpg', size: '200x150>' }
    end
  end
    )
    end


  end

end
