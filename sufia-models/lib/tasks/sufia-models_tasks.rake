require 'net/http'

namespace :solr do
  desc "Enqueue a job to resolrize the repository objects"
  task reindex: :environment do
    CurationConcerns.queue.push(ResolrizeJob.new)
  end
end

namespace :sufia do
  namespace :jetty do

    FULLTEXT_JARS = %w(
        org/apache/james/apache-mime4j-core/0.7.2/apache-mime4j-core-0.7.2.jar
        org/apache/james/apache-mime4j-dom/0.7.2/apache-mime4j-dom-0.7.2.jar
        org/apache/solr/solr-cell/4.0.0/solr-cell-4.0.0.jar
        org/bouncycastle/bcmail-jdk15/1.45/bcmail-jdk15-1.45.jar
        org/bouncycastle/bcprov-jdk15/1.45/bcprov-jdk15-1.45.jar
        de/l3s/boilerpipe/boilerpipe/1.1.0/boilerpipe-1.1.0.jar
        org/apache/commons/commons-compress/1.4.1/commons-compress-1.4.1.jar
        dom4j/dom4j/1.6.1/dom4j-1.6.1.jar
        org/apache/pdfbox/fontbox/1.7.0/fontbox-1.7.0.jar
        com/ibm/icu/icu4j/49.1/icu4j-49.1.jar
        com/googlecode/mp4parser/isoparser/1.0-RC-1/isoparser-1.0-RC-1.jar
        jdom/jdom/1.0/jdom-1.0.jar
        org/apache/pdfbox/jempbox/1.7.0/jempbox-1.7.0.jar
        com/googlecode/juniversalchardet/juniversalchardet/1.0.3/juniversalchardet-1.0.3.jar
        com/drewnoakes/metadata-extractor/2.4.0-beta-1/metadata-extractor-2.4.0-beta-1.jar
        edu/ucar/netcdf/4.2-min/netcdf-4.2-min.jar
        org/apache/pdfbox/pdfbox/1.7.0/pdfbox-1.7.0.jar
        org/apache/poi/poi/3.8/poi-3.8.jar
        org/apache/poi/poi-ooxml/3.8/poi-ooxml-3.8.jar
        org/apache/poi/poi-ooxml-schemas/3.8/poi-ooxml-schemas-3.8.jar
        org/apache/poi/poi-scratchpad/3.8/poi-scratchpad-3.8.jar
        rome/rome/0.9/rome-0.9.jar
        org/ccil/cowan/tagsoup/tagsoup/1.2.1/tagsoup-1.2.1.jar
        org/apache/tika/tika-core/1.2/tika-core-1.2.jar
        org/apache/tika/tika-parsers/1.2/tika-parsers-1.2.jar
        org/gagravarr/vorbis-java-core/0.1/vorbis-java-core-0.1.jar
        org/gagravarr/vorbis-java-tika/0.1/vorbis-java-tika-0.1.jar
        xerces/xercesImpl/2.9.1/xercesImpl-2.9.1.jar
        org/apache/xmlbeans/xmlbeans/2.3.0/xmlbeans-2.3.0.jar
        org/tukaani/xz/1.0/xz-1.0.jar
        org/aspectj/aspectjrt/1.8.5/aspectjrt-1.8.5.jar
      )

    desc 'Configure jetty with full-text indexing'
    task config: :download_jars do
      Rake::Task['jetty:config'].invoke
    end

    desc 'Download Solr full-text extraction jars'
    task :download_jars do
      puts "Downloading full-text jars from maven.org ..."
      fulltext_dir = 'jetty/solr/lib/contrib/extraction/lib'
      FileUtils.mkdir_p(fulltext_dir) unless File.directory?(fulltext_dir)
      Dir.chdir(fulltext_dir) do
        FULLTEXT_JARS.each do |jar|
          destination = jar.split('/').last
          download_from_maven(jar, destination) unless File.exists?(destination)
        end
      end
    end
  end
end

def download_from_maven url, dst
  full_url = '/remotecontent?filepath=' + url
  file = File.open(dst, "wb")
  endpoint = Net::HTTP.new('search.maven.org', 443)
  endpoint.use_ssl = true
  endpoint.start do |http|
    puts "Fetching #{full_url}"
    begin
      http.request_get(full_url) do |resp|
        resp.read_body { |segment| file.write(segment) }
      end
    ensure
      file.close
    end
  end
end
