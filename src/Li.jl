module Li

using Base64: base64encode
function display_mp4(filename)
    display("text/html", string("""<video autoplay controls><source src="data:video/x-m4v;base64,""",
        base64encode(open(read, filename)), """" type="video/mp4"></video>"""))
end

"""
Given a `mother_seed`, generates `num_seeds` number of unique seeds and runs
the given `inner_func` on all of them in series.

NOTE: in the implementation, this code generates an inner seed which appends an
offset in the digit place to the left of the `mother_seed`, which ensures that
all the mother seeds yield unique inner seeds, at the cost of potentially making
the seed number large.  Therefore, it is suggested to keep the mother seeds as
single digit numbers.
"""
function call_ensemble(inner_func, mother_seed, num_seeds)
    inner_seeds = map(1:num_seeds) do offset
        num_digits = Int(round(log10(mother_seed))) + 1
        j = offset * 10^(num_digits + 1)
        mother_seed + j
    end

    if unique(inner_seeds) != inner_seeds
        throw(ErrorException("This should not happen."))
    end

    for seed in inner_seeds
        inner_func(seed)
        @info "Completed single run with seed = $(seed)"
    end

end

end # module Li
