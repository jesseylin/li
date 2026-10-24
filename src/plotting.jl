module Plotting

using AlgebraOfGraphics
using CairoMakie
using ColorSchemes

export pt, inch
export set_publication_theme!
export log10_ticks, log10_minor_ticks, log10_axis
export fix_svg_physical_size!, save_figure
export DPI, CSS_PT, CSS_INCH, FIG_SIZE, PALETTE
export CONTOUR_VISUAL, SCATTER_ENDPOINT_VISUAL, SCATTER_VISUAL
export LINE_VISUAL, FITLINE_VISUAL

"""
    _seed_fontpaths_from_fontconfig!()

Seed Makie's FreeType font search paths from fontconfig when they come up
empty, and return the resulting path list.
"""
function _seed_fontpaths_from_fontconfig!()
    # `Makie.FreeTypeAbstraction.fontpaths()` is a mutable global populated once
    # at load time by scanning XDG data directories. NixOS and Home Manager
    # deliberately keep fonts off those paths — they run `fc-cache` against the
    # immutable store path instead — so there the list is empty and every family
    # lookup fails: both `_find_system_font_path` and the bare `font = "Arial"`
    # theme attributes, which Makie resolves through the same global. On Linux
    # fontconfig is the font discovery API, so ask it. Where `fc-list` is absent
    # (macOS, minimal containers) this is a no-op beyond a warning; Makie's own
    # paths are usually populated there.
    paths = Makie.FreeTypeAbstraction.fontpaths()
    isempty(paths) || return paths
    listing = try
        read(Cmd(["fc-list", "--format=%{file}\n"]), String)
    catch err
        @warn "Could not query fontconfig for font directories" exception = err
        return paths
    end
    files = filter(!isempty, split(listing, "\n"))
    for dir in unique(dirname.(files))
        isdir(dir) && dir ∉ paths && push!(paths, dir)
    end
    return paths
end

"""
    _find_system_font_path(family; style = "Regular")

Find a system font file matching `family` and `style` using Makie's FreeType
font search paths.
"""
function _find_system_font_path(family; style = "Regular")
    family_lower = lowercase(family)
    style_lower = lowercase(style)
    dirs = Makie.FreeTypeAbstraction.fontpaths()
    for dir in dirs
        isdir(dir) || continue
        for (root, _, files) in walkdir(dir)
            for file in files
                path = joinpath(root, file)
                font = Makie.FreeTypeAbstraction.try_load(path)
                font === nothing && continue
                try
                    if lowercase(font.family_name) == family_lower && lowercase(font.style_name) == style_lower
                        return path
                    end
                finally
                    finalize(font)
                end
            end
        end
    end
    error(
        "Could not find font family $(repr(family)) with style $(repr(style)) " *
            "in font directories: $(isempty(dirs) ? "(none)" : join(dirs, ", "))",
    )
end

const INCH_PER_PT = 1 / 64
const DPI = 300
const CSS_PT = 4 / 3
const CSS_INCH = 96

"""
    pt(x)

Convert typographic points to Makie display units (based on its default 96
DPI). Use for theme attributes, not figure size.
"""
pt(x) = x * CSS_PT

"""
    inch(x)

Convert inches to Makie display units. Use for figure or axis size.
"""
inch(x) = x * CSS_INCH

const EM = pt(9)
const FIG_WIDTH = 6.75 * CSS_INCH
const FIG_ASPECT = 4 / 3
const FIG_SIZE = (FIG_WIDTH, FIG_WIDTH / FIG_ASPECT)

red_fig1 = convert(ColorSchemes.Colors.HSV, ColorSchemes.Colors.colorant"#F53A2C")
red_fig1_lighter = ColorSchemes.Colors.HSV(red_fig1.h, red_fig1.s, 1.2 * red_fig1.v)
const PALETTE = (;
    primary = ColorSchemes.Colors.colorant"#5157A3",
    secondary = ColorSchemes.Colors.colorant"#9F4999",
    black = ColorSchemes.grays[1],
    gray = ColorSchemes.grays[128],
    primary_light = ColorSchemes.seaborn_pastel[1],
    secondary_light = ColorSchemes.seaborn_pastel[5],
    primary_seaborn_muted = ColorSchemes.seaborn_muted[1],
    secondary_seaborn_muted = ColorSchemes.seaborn_muted[2],
    tertiary_seaborn_muted = ColorSchemes.seaborn_muted[3],
    red_trajectory = red_fig1,
    red_trajectory_on_black = red_fig1_lighter,
    red_trajectory_v1 = ColorSchemes.Colors.colorant"#CF2924",
    red_trajectory_saturated_v1 = ColorSchemes.Colors.colorant"#E70F0C",
    surface_gray = ColorSchemes.Colors.colorant"#F5FBFB",
    surface_mesh = ColorSchemes.Colors.colorant"#C0C5C6",
)

const CONTOUR_VISUAL = visual(
    Contour;
    color = (PALETTE.black, 0.1), levels = 20, linewidth = pt(1),
)
const SCATTER_ENDPOINT_VISUAL = visual(
    Scatter;
    markersize = pt(5), strokecolor = PALETTE.black,
)
const HLINE_VISUAL = visual(HLines; linewidth = pt(2))
const SCATTER_VISUAL = visual(
    Scatter;
    color = :transparent, strokewidth = pt(1),
    markersize = pt(6), strokecolor = PALETTE.gray,
)
const LINE_VISUAL = visual(Lines; linewidth = pt(2))
const FITLINE_VISUAL = visual(
    Lines; linestyle = :dash, linewidth = pt(2),
)

"""Set the Arial/Fira Math publication theme for subsequent Makie figures."""
function set_publication_theme!()
    # Seeded here rather than in an `__init__` so the side effect stays tied to
    # the call that needs fonts, and `using Li` does not pay for shelling out to
    # fontconfig. This must precede `set_theme!` so that Makie resolves the bare
    # family names below against the seeded paths.
    _seed_fontpaths_from_fontconfig!()

    set_theme!(
        Theme(
            size = FIG_SIZE,
            font = "Arial",
            fontsize = 1EM,
            figure_padding = EM / 2,
            Axis = (;
                spinewidth = pt(1),
                topspinevisible = false,
                rightspinevisible = false,
                xgridvisible = false,
                ygridvisible = false,
                xtickwidth = pt(1.0),
                ytickwidth = pt(1.0),
                xticksize = pt(1.5),
                yticksize = pt(1.5),
                xminorticksize = pt(1.0),
                yminorticksize = pt(1.0),
                xminortickwidth = pt(0.5),
                yminortickwidth = pt(0.5),
                xlabelpadding = pt(1),
                ylabelpadding = pt(3),
            ),
            Colorbar = (;
                labelpadding = pt(6),
                tickwidth = pt(1.0),
                ticksize = pt(1.5),
                minorticksize = pt(1.0),
                minortickwidth = pt(0.5),
            ),
            Legend = (;
                tellheight = false,
                tellwidth = false,
                rowgap = -2 / 3 * EM,
                framevisible = false,
            ),
            Label = (; font = "Arial Black", halign = :left),
            Lines = (; linewidth = pt(2)),
            HLines = (; linewidth = pt(2)),
            VLines = (; linewidth = pt(2)),
            Scatter = (;
                color = :transparent, strokewidth = pt(1),
                markersize = pt(6), strokecolor = PALETTE.gray,
            ),
        ),
    )

    math = _find_system_font_path("Fira Math")
    # HACK: point MathTeXEngine's built-in math font at Fira Math because
    # `_delimiter_element` draws `(`, `)`, `[`, `]`, … from
    # `_default_fonts[:math]` (NewComputerModern) and ignores the font family,
    # so even `L"\text{time (h)}"` got serif parentheses
    # (https://forge.jesseylin.com/jylin/rien/issues/860).
    Makie.MathTeXEngine._default_fonts[:math] = math
    return Makie.MathTeXEngine.set_texfont_family!(;
        regular = _find_system_font_path("Arial"),
        italic = _find_system_font_path("Arial"; style = "Italic"),
        bold = _find_system_font_path("Arial"; style = "Bold"),
        bolditalic = _find_system_font_path("Arial"; style = "Bold Italic"),
        math,
    )
end

const SUPERSCRIPT_DIGITS = Dict(
    '0' => '⁰', '1' => '¹', '2' => '²', '3' => '³', '4' => '⁴',
    '5' => '⁵', '6' => '⁶', '7' => '⁷', '8' => '⁸', '9' => '⁹',
    '-' => '⁻',
)
superscript_number(n::Integer) = join(SUPERSCRIPT_DIGITS[c] for c in string(n))

"""Generate major tick positions and `10ⁿ` labels for log10-transformed data."""
log10_ticks(exponents) = (
    collect(exponents),
    ["10$(superscript_number(i))" for i in exponents],
)

"""Generate minor log10 tick positions for log10-transformed data."""
log10_minor_ticks(exponents) = [
    exponent + log10(multiplier) for exponent in exponents[begin:(end - 1)] for multiplier in 2:9
]

"""Derive log10-transformed axis limits, major ticks, and minor ticks."""
function log10_axis(lims)
    xlo, xhi, ylo, yhi = lims
    x_range = floor(Int, xlo):ceil(Int, xhi)
    y_range = floor(Int, ylo):ceil(Int, yhi)
    return (;
        limits = lims,
        xticks = log10_ticks(x_range),
        yticks = log10_ticks(y_range),
        xminorticks = log10_minor_ticks(x_range),
        yminorticks = log10_minor_ticks(y_range),
    )
end

"""
    fix_svg_physical_size!(path)

Rewrite a CairoMakie SVG's root width and height as inch units inferred from
its `viewBox`, while preserving its coordinate system.
"""
function fix_svg_physical_size!(path::AbstractString)
    svg = read(path, String)
    svg_match = match(r"<svg\b[^>]*>", svg)
    svg_match === nothing && error("Could not find root <svg> tag in SVG: $path")

    svg_tag = svg_match.match
    viewbox_match = match(
        r"\bviewBox=\"\s*([-\d.eE+]+)\s+([-\d.eE+]+)\s+([-\d.eE+]+)\s+([-\d.eE+]+)\s*\"",
        svg_tag,
    )
    viewbox_match === nothing && error("Could not find viewBox in root <svg> tag: $path")

    width_in = parse(Float64, viewbox_match.captures[3]) / CSS_INCH
    height_in = parse(Float64, viewbox_match.captures[4]) / CSS_INCH
    format_inches(x) = isinteger(x) ? string(Int(x)) : string(x)

    width_attr = "width=\"$(format_inches(width_in))in\""
    height_attr = "height=\"$(format_inches(height_in))in\""
    new_svg_tag = replace(svg_tag, r"\swidth=\"[^\"]*\"" => " $width_attr")
    new_svg_tag = replace(new_svg_tag, r"\sheight=\"[^\"]*\"" => " $height_attr")

    write(path, replace(svg, svg_tag => new_svg_tag; count = 1))
    return path
end

"""
    save_figure(fig, name; output_dir, formats = ["png", "svg", "eps"], dpi = DPI, kwargs...)

Save `fig` as unversioned PNG, SVG, and EPS files (or a selected subset) in the
explicit `output_dir`. SVG files are postprocessed with inch-based dimensions.
"""
function save_figure(
        fig,
        name;
        output_dir::AbstractString,
        formats = ["png", "svg", "eps"],
        dpi = DPI,
        kwargs...,
    )
    mkpath(output_dir)
    for format in formats
        path = joinpath(output_dir, "$(name).$(format)")
        save(path, fig; px_per_unit = dpi / CSS_INCH, kwargs...)
        format == "svg" && fix_svg_physical_size!(path)
    end
    return nothing
end

end # module Plotting
