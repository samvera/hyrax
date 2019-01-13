# Usage : rake add_entry['fr','blacklight.search.my_new_command','Ma nouvelle commande']
desc "Insert new value at given path for source locale"
task :add_entry, [:locale, :path, :value] do |t, args|
  raise "Mandatory parameters : target locale, dotted path from locale, value to insert" unless args.locale && args.path && args.value
  path = "#{args.locale}.#{args.path}"
  p "Insert value #{args.value} at path <#{path}> for locale #{args.locale}"
  source_path = File.expand_path("../../config/locales/hyrax.#{args.locale}.yml", __FILE__)
  source_hash = Psych.load_file(source_path)
  source_hash.dig_or_create(path, args.value)
  File.open(source_path, 'w') {|f| f << source_hash.to_yaml(line_width: -1)}
  Rake::Task["i18n_sorter"].invoke
end

# Usage : rake quick_translate['fr','blacklight.search.my_new_command']
desc "Propagates a new value from source locale to other languages"
task :quick_translate, [:locale, :path] do |t, args|
  raise "Mandatory parameters : source locale, dotted path from locale" unless args.locale && args.path
  yandex_key = File.read(File.expand_path('yandex.key', File.dirname(__FILE__)))
  raise "Please add your Yandex key in yandex.key file" if yandex_key.empty?
  source_path = File.expand_path("../../config/locales/hyrax.#{args.locale}.yml", __FILE__)
  source_hash = Psych.load_file(source_path)
  path = "#{args.locale}.#{args.path}"
  source_value_to_insert = source_hash.dig_or_create(path, args.value)
  raise "No value at #{path} in #{source_path}" unless source_value_to_insert
  p "Translate value #{source_value_to_insert} at path <#{path}> from locale #{args.locale} to other languages"
  (['de', 'en', 'es', 'fr', 'it', 'pt-BR', 'zh']-[args.locale]).each do |locale|
    target_locale_path = File.expand_path("../../config/locales/hyrax.#{locale}.yml", __FILE__)
    target_locale_hash = Psych.load_file(target_locale_path)
    target_path = "#{locale}.#{args.path}"
    translated_value = yandex_translate(source_value_to_insert, from: args.locale[0..1], to: locale[0..1], key: yandex_key)
    p "Translated value for locale #{locale} : #{translated_value}"
    if translated_value.empty?
      p "**************Warning ! Translation empty for locale #{locale}**********"
      next
    end
    target_locale_hash.dig_or_create(target_path, translated_value)
    File.open(target_locale_path, 'w') {|f| f << target_locale_hash.to_yaml(line_width: -1)}
  end
  Rake::Task["i18n_sorter"].invoke
end

def yandex_translate(value, from:, to:, key:)
  require 'faraday'
  require 'nokogiri'
  response = Faraday.new("https://translate.yandex.net/api/v1.5/tr/translate?key=#{key}&text=#{value}&lang=#{from}-#{to}").get
  Nokogiri::XML(response.body).xpath('//Translation/text').first.text
end

class Hash
  def dig_or_create(path, value_to_insert = nil)
    parts = path.split '.', 2
    current_key = parts[0]
    unless self[current_key]
      p "Creating key #{current_key}"
      self[current_key] = parts[1].nil? ? value_to_insert : Hash.new
    end
    match = self[current_key]
    unless parts[1]
      return match
    else
      return match.dig_or_create(parts[1], value_to_insert)
    end
  end
end




