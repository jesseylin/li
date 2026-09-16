# 利

A package with some utilities I find useful.

## Install

```julia
using Pkg
Pkg.add(url = "https://github.com/jesseylin/Li")
```

## Top-level exports

- `display_mp4(filename)` — render a video file inline as HTML in a notebook
  or REPL that supports rich display.
- `call_ensemble(inner_func, mother_seed, num_seeds)` — run `inner_func` in
  series over `num_seeds` unique seeds derived from `mother_seed`.
- `parse_param_from_filename(fieldname, filename; sep = "__")` — parse a
  `key1=val1__key2=val2.ext`-style filename and return the value for `fieldname`.
- `@comment` — a no-op macro for annotating code without deleting it.

## Plotting

`Li.Plotting` provides reusable CairoMakie publication-plot helpers without
domain-specific dependencies. Save figures to an explicit artifact directory:

```julia
import Li

fig = Li.Plotting.Figure(size = (Li.Plotting.inch(4), Li.Plotting.inch(3)))
Li.Plotting.save_figure(fig, "example"; output_dir = "plots")
```

This writes unversioned `example.png`, `example.svg`, and `example.eps` files.
The SVG's physical dimensions are written in inches for layout-tool compatibility.

`Li.Plotting.set_publication_theme!()` hard-requires **Arial** (Regular,
Italic, Bold, and Bold Italic) and **Fira Math** to be installed and
discoverable by Makie/fontconfig; it `error()`s naming the missing family
rather than falling back to a substitute font, since a silent substitution
would be wrong for publication figures.
