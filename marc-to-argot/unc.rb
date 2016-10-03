to_field "id", extract_marc("907a", :first => true) do |marc_record, accumulator, context|
    accumulator.collect! {|s| "UNC#{s.delete("b.")}"}
end

to_field "source", literal("UNC")