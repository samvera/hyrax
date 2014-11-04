FactoryGirl.define do
  factory :generic_file do
    transient do
      depositor "archivist1@example.com"
    end
    before(:create) do |gf, evaluator|
      gf.apply_depositor_metadata evaluator.depositor
    end

    factory :public_file do
      read_groups ["public"]
    end

    factory :fixture do
      factory :public_pdf do
        transient do
          id "fixture-pdf"
        end
        initialize_with { new(id: id) }
        read_groups ["public"]
        resource_type ["Dissertation"]
        subject %w"lorem ipsum dolor sit amet"
        title ["fake_document.pdf"]
        before(:create) do |gf|
          gf.apply_depositor_metadata "archivist1@example.com"
          gf.title = ["Fake Document Title"]
        end
      end
      factory :public_mp3 do
        transient do
          id "fixture-mp3"
        end
        initialize_with { new(id: id) }
        subject %w"consectetur adipisicing elit"
        title ["Test Document MP3.mp3"]
        before(:create) do |gf|
          gf.apply_depositor_metadata "archivist1@example.com"
        end
        read_groups ["public"]
      end
      factory :public_wav do
        transient do
          id "fixture-wav"
        end
        initialize_with { new(id: id) }
        resource_type ["Audio", "Dataset"]
        read_groups ["public"]
        title ["Fake Wav File.wav"]
        subject %w"sed do eiusmod tempor incididunt ut labore"
        before(:create) do |gf|
          gf.apply_depositor_metadata "archivist1@example.com"
        end
      end
    end
  end
end
