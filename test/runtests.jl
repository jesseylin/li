using Test, Li, Li.Plotting

filepath = "/fake/path/example/data/2025-02-17T22:15:56.524__alpha=1.0__beta=2__seed=1234.jld2"

@test parse_param_from_filename("seed", filepath) == "1234"

@testset "Plotting" begin
    @test pt(1) == CSS_PT
    @test inch(1) == CSS_INCH
    @test log10_ticks(-1:1) == ([-1, 0, 1], ["10⁻¹", "10⁰", "10¹"])
    @test log10_minor_ticks(0:1) == log10.(2:9)
    @test log10_axis((-0.2, 1.2, 0.0, 1.0)).xticks == log10_ticks(-1:2)

    mktempdir() do dir
        svg_path = joinpath(dir, "physical-size.svg")
        write(svg_path, "<svg width=\"384\" height=\"288\" viewBox=\"0 0 384 288\"></svg>")
        @test fix_svg_physical_size!(svg_path) == svg_path
        fixed_svg = read(svg_path, String)
        @test occursin("width=\"4in\"", fixed_svg)
        @test occursin("height=\"3in\"", fixed_svg)
        @test occursin("viewBox=\"0 0 384 288\"", fixed_svg)

        invalid_path = joinpath(dir, "invalid.svg")
        write(invalid_path, "not an SVG")
        @test_throws ErrorException fix_svg_physical_size!(invalid_path)
        write(invalid_path, "<svg width=\"1\" height=\"1\"></svg>")
        @test_throws ErrorException fix_svg_physical_size!(invalid_path)

        fig = Li.Plotting.Figure(size = (CSS_INCH, CSS_INCH / 2))
        save_figure(fig, "smoke"; output_dir = dir, formats = ["svg"], dpi = CSS_INCH)
        smoke_svg = read(joinpath(dir, "smoke.svg"), String)
        @test occursin(r"<svg\b[^>]*width=\"1in\"[^>]*height=\"0.5in\"", smoke_svg)
        @test occursin(r"<svg\b[^>]*viewBox=\"[^\"]+\"", smoke_svg)
    end
end

# Font discovery is checked without depending on any font being installed: the
# search paths are replaced by an empty directory for the duration.
@testset "Font paths" begin
    paths = Li.Plotting.Makie.FreeTypeAbstraction.fontpaths()
    saved = copy(paths)
    try
        mktempdir() do dir
            append!(empty!(paths), [dir])
            # Seeding mutates Makie's path list in place, and leaves an
            # already-populated list alone rather than re-querying fontconfig.
            @test Li.Plotting._seed_fontpaths_from_fontconfig!() === paths
            @test paths == [dir]

            # A genuinely missing family still errors, and names where it looked.
            err = try
                Li.Plotting._find_system_font_path("No Such Font Family")
                nothing
            catch err
                err
            end
            @test err isa ErrorException
            @test occursin("No Such Font Family", err.msg)
            @test occursin("font directories: $(dir)", err.msg)
        end
    finally
        append!(empty!(paths), saved)
    end
end
