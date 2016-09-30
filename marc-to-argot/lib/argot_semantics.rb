# Encoding: UTF-8

require 'traject/marc_extractor'

module Traject::Macros

  module ArgotSemantics
    # shortcut
    MarcExtractor = Traject::MarcExtractor

    def argot_title_object
        lambda do |record,accumulator|
            st = ArgotSemantics.get_title_object(record)
            accumulator << st if st
        end
    end

    def self.get_title_object(record,extract_fields = "245ak:210")
        titleobject = {
            :sort => Marc21Semantics.get_sortable_title(record)
        }

        vernacular_bag = ArgotSemantics.create_vernacular_bag(record,extract_fields)

        Traject::MarcExtractor.cached(extract_fields, :alternate_script => false).collect_matching_lines(record) do |field, spec, extractor|
            str = extractor.collect_subfields(field,spec).first
            non_filing = field.indicator2.to_i
            str = str.slice(non_filing, str.length)
            str = Marc21.trim_punctuation(str)

            marc_match_suffix = ''

            field.subfields.each do |subfield|
                if subfield.code == '6'
                    marc_match_suffix = subfield.value[subfield.value.index("-")..-1]
                end
            end

            vernacular = vernacular_bag[field.tag + marc_match_suffix]

            case field.tag
            when '245'
                titleobject[:main] = {
                    :value => str,
                    :marc => field.tag,
                    :vernacular => vernacular
                }
            when '210'
                titleobject[:abbrv] = {
                    :value => str,
                    :marc => field.tag,
                    :vernacular => vernacular
                }
            else
            end
        end

        titleobject
    end

    def self.create_vernacular_bag(record, extract_fields)
        vernacular_bag = {}

        Traject::MarcExtractor.cached(extract_fields, :alternate_script => :only).collect_matching_lines(record) do |field, spec, extractor|

            str = extractor.collect_subfields(field,spec).first
            non_filing = field.indicator2.to_i
            str = str.slice(non_filing, str.length)
            str = Marc21.trim_punctuation(str)

            field.subfields.each do |subfield|
                if subfield.code == '6'
                    index_of_slash = subfield.value.rindex("/")
                    lang_code = subfield.value[index_of_slash..-1] if index_of_slash
                    marc_match = subfield.value[0..(index_of_slash-1)] if index_of_slash
                    vernacular_bag[marc_match] = {
                        :lang => lang_code,
                        :value => str
                    }
                end
            end
        end

        vernacular_bag
    end

  end
end