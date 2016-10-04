# Encoding: UTF-8

require 'traject/marc_extractor'

module Traject::Macros

    module ArgotSemantics
        # shortcut
        MarcExtractor = Traject::MarcExtractor

        ######
        # Lambda for Title
        ######
        def argot_title_object(spec)
            lambda do |record,accumulator|
                st = ArgotSemantics.get_title_object(record,spec)
                accumulator << st if st
            end
        end

        ######
        # Lambda for Publisher
        ######
        def argot_publisher_object
            lambda do |record,accumulator|
                st = ArgotSemantics.get_publisher_object(record)
                accumulator << st if st
            end
        end

        ######
        # Lambda for Authors
        ######
        def argot_get_authors(spec)
            lambda do |record,accumulator|
                st = ArgotSemantics.get_authors(record,spec)
                accumulator << st if st
            end
        end

        ######
        # Extract a marc string from a set of marc subfields
        ######
        def self.trim_marc_string(extractor, field, spec)
            str = extractor.collect_subfields(field,spec).first
            non_filing = field.indicator2.to_i
            str = str.slice(non_filing, str.length)
            str = Marc21.trim_punctuation(str)
            str
        end

        ################################################
        # Create a nested title object
        ######
        def self.get_title_object(record,extract_fields = "245")
            titleobject = {
                :sort => Marc21Semantics.get_sortable_title(record)
            }

            vernacular_bag = ArgotSemantics.create_vernacular_bag(record,extract_fields)

            Traject::MarcExtractor.cached(extract_fields, :alternate_script => false).each_matching_line(record) do |field, spec, extractor|
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


        ################################################
        # Create a nested authors object
        ######
        def self.get_authors(record,extract_fields = "100")
             authors = {
                :sort => Marc21Semantics.get_sortable_author(record),
                :main => [],
                :director => [],
                :other => [],
                :uncontrolled => [],
            }

            vernacular_bag = ArgotSemantics.create_vernacular_bag(record,extract_fields)

            Traject::MarcExtractor.cached(extract_fields, :alternate_script => false).each_matching_line(record) do |field, spec, extractor|
                str = ArgotSemantics.trim_marc_string(extractor, field, spec)

                marc_match_suffix = ''
                has_director = false

                field.subfields.each do |subfield|
                    if subfield.code == '6'
                        marc_match_suffix = subfield.value[subfield.value.index("-")..-1]
                    end
                    if subfield.code == '4' && subfield.value == 'drt'
                        has_director = true
                    end
                end

                vernacular = vernacular_bag[field.tag + marc_match_suffix]

                if has_director
                    authors[:director] << {
                        :name => str,
                        :vernacular => vernacular,
                        :marc_source => field.tag
                    }
                end

                if field.tag.to_i < 700
                    authors[:main] << {
                        :name => str,
                        :vernacular => vernacular,
                        :marc_source => field.tag
                    }
                elsif field.tag == '720'
                    authors[:uncontrolled] << {
                        :name => str,
                        :vernacular => vernacular,
                        :marc_source => field.tag
                    }
                else
                    authors[:other] << {
                        :name => str,
                        :vernacular => vernacular,
                        :marc_source => field.tag
                    }
                end
            end

            #cleanup
            authors.each do |k,v|
                if v.empty?
                    authors.delete(k)
                end
            end

            authors
        end


        ##########################################
        # Create a nested publisher object
        ######
        def self.get_publisher_object(record)

            publisher = {
                :number => '',
                :name => '',
                :imprint => '',
                :vernacular => '',
                :marc_source => '',
            }

            number = Traject::MarcExtractor.cached('264b', :alternate_script => false, :first => true).extract(record)
            if !number.empty?
                publisher[:number] = number.join("")
            end


            vernacular_bag = ArgotSemantics.create_vernacular_bag(record,"260:264")

            marc_match_suffix = ''
            name = []
            imprint = []

            Traject::MarcExtractor.cached('264b', :alternate_script => false).each_matching_line(record) do |field, spec, extractor|

                if field.indicator2 == 1
                    field.subfields.each do |subfield|
                        if subfield.code == '6'
                            marc_match_suffix = subfield.value[subfield.value.index("-")..-1]
                        end

                        if subfield.code == 'b'
                            publisher << subfield.value
                        end

                        if ['a','b','c'].include?(subfield.code)
                            imprint << subfield.value
                        end
                    end

                    vernacular = vernacular_bag[field.tag + marc_match_suffix];
                    if vernacular
                        publisher[:vernacular] = vernacular
                    end

                    if imprint != ''
                        publisher[name] = name.join(" ")
                        publisher[imprint] = imprint.join(" ")
                        publisher[marc_source] = '264'
                    end
                end
            end

            if publisher[:imprint] == ''

                Traject::MarcExtractor.cached('260', :alternate_script => false).each_matching_line(record) do |field, spec, extractor|

                    field.subfields.each do |subfield|
                        if subfield.code == '6'
                            marc_match_suffix = subfield.value[subfield.value.index("-")..-1]
                        end

                        if subfield.code == 'b' || subfield.code == 'f'
                            name << subfield.value
                        end

                        if ['a','b','c','e','f','g'].include?(subfield.code)
                            imprint << subfield.value
                        end
                    end

                    vernacular = vernacular_bag[field.tag + marc_match_suffix];
                    if vernacular
                        publisher[:vernacular] = vernacular
                    end

                    if imprint != ''
                        publisher[:name] = name.join(" ")
                        publisher[:imprint] = imprint.join(" ")
                        publisher[:marc_source] = '260'
                    end

                end
            end

            publisher
        end


        ######
        # Create a bag of vernacular strings to pair with other marc fields
        ######
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