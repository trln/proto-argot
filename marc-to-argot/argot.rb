$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), './lib'))


# A sample traject configuration, save as say `traject_config.rb`, then
# run `traject -c traject_config.rb marc_file.marc` to index to
# solr specified in config file, according to rules specified in
# config file


# To have access to various built-in logic
# for pulling things out of MARC21, like `marc_languages`
require 'traject/macros/marc21_semantics'
extend  Traject::Macros::Marc21Semantics

# To have access to the traject marc format/carrier classifier
require 'traject/macros/marc_format_classifier'
extend Traject::Macros::MarcFormats

require 'argot_semantics'
extend Traject::Macros::ArgotSemantics

# In this case for simplicity we provide all our settings, including
# solr connection details, in this one file. But you could choose
# to separate them into antoher config file; divide things between
# files however you like, you can call traject with as many
# config files as you like, `traject -c one.rb -c two.rb -c etc.rb`
settings do
  provide "writer_class_name", "Traject::JsonWriter"
  provide "output_file", "argot_out.json"
  provide 'processing_thread_pool', 3
  provide "json_writer.pretty_print", true
end

to_field "title", argot_title_object("245abnp:210ab:130adfghklmnoprs:242abhnp:246abhnp:247abhnp:730adfghklmnoprst:740ahnp:780abcdghnkstxz:785abcdghikmnstxz")

to_field "statement_of_responsibility", argot_gvo("245c")
to_field "edition", argot_gvo("250ab")

to_field "publication_year", marc_publication_date

to_field "authors", argot_get_authors("100abcdegq:110abcdefgn:111abcdefngq:700abcdeq:710abcde:711abcdeq:720a")

######
# Series
######
to_field "series", argot_series("440anpvx")
to_field "series", argot_series("490avx")

######
# ISBN / ISSN / UPC
#####
to_field "isbn", extract_marc("020az:024a")
to_field "syndetics_isbn", extract_marc("020a")
to_field "issn", extract_marc("022ayz")
to_field "upc" do |record, acc|
    Traject::MarcExtractor.cached("024a").each_matching_line(record) do |field, spec, extractor|
        if field.indicator1 == '1'
            acc << extractor.collect_subfields(field,spec).first
        end
    end
end


to_field "publisher", argot_publisher_object


######
# MISC
######
to_field "cartographic_data", extract_marc("255abcdefg")