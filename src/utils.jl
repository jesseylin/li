"""
Given a `filename` with format `key1=val1__key2=val2.ext`, parses and returns
the values given a key `fieldname`.
"""
function parse_param_from_filename(fieldname::String, filename::String; sep="__")
    regstr = Regex("$(fieldname)=(.+)")

    # drop all filesystem related metadata from path
    name, _ = splitext(basename(filename))

    fields = split(name, sep)
    field_matches = map(x -> match(regstr, x), fields)

    try
        field_match = only(filter(!isnothing, field_matches))
        match_str = only(field_match.captures)
        return string(match_str)
    catch e
        if isa(e, ArgumentError)
            throw(ArgumentError("No match found for $(fieldname) in $(name)."))
        else
            rethrow(e)
        end
    end
end
