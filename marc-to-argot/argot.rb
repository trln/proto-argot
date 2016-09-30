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

require 'argon_semantics'
extend Traject::Macros::ArgonSemantics

# In this case for simplicity we provide all our settings, including
# solr connection details, in this one file. But you could choose
# to separate them into antoher config file; divide things between
# files however you like, you can call traject with as many
# config files as you like, `traject -c one.rb -c two.rb -c etc.rb`
settings do
  provide "writer_class_name", "Traject::JsonWriter"
  provide "output_file", "argon_out.json"
  provide 'processing_thread_pool', 3
end

# Extract first 001, then supply code block to add "bib_" prefix to it
to_field "id", extract_marc("001", :first => true) do |marc_record, accumulator, context|
  accumulator.collect! {|s| "bib_#{s}"}
end

to_field "title", argon_title_object


