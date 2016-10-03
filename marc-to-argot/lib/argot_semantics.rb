# Encoding: UTF-8

require 'traject/marc_extractor'

module Traject::Macros

    module ArgotSemantics
        # shortcut
        MarcExtractor = Traject::MarcExtractor

        def argot_title_object(spec)
            lambda do |record,accumulator|
                st = ArgotSemantics.get_title_object(record,spec)
                accumulator << st if st
            end
        end

        def self.trim_marc_string(extractor, field, spec)
            str = extractor.collect_subfields(field,spec).first
            non_filing = field.indicator2.to_i
            str = str.slice(non_filing, str.length)
            str = Marc21.trim_punctuation(str)
            str
        end

        def self.get_title_object(record,extract_fields = "245")
            titleobject = {
                :sort => Marc21Semantics.get_sortable_title(record)
            }

            vernacular_bag = ArgotSemantics.create_vernacular_bag(record,extract_fields)

            Traject::MarcExtractor.cached(extract_fields, :alternate_script => false).collect_matching_lines(record) do |field, spec, extractor|
                str = ArgotSemantics.trim_marc_string(extractor, field, spec)

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
                when '130'
                    titleobject[:journal] = {
                        :value => str,
                        :marc => field.tag,
                        :vernacular => vernacular
                    }
                when '242'
                    titleobject[:translation] = {
                        :value => str,
                        :marc => field.tag,
                        :vernacular => vernacular
                    }
                else
                    titleobject[:alt] << {
                        :value => str,
                        :marc => field.tag,
                        :vernacular => vernacular
                    }
                end
            end

            titleobject
        end

        def self.create_vernacular_bag(record, extract_fields)
            vernacular_bag = {}

            Traject::MarcExtractor.cached(extract_fields, :alternate_script => :only).collect_matching_lines(record) do |field, spec, extractor|

                str = ArgotSemantics.trim_marc_string(extractor, field, spec)

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