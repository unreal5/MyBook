# AI Assistant Project Instructions

This repository is a LaTeX book project with a custom document class (`MyBook.cls`) plus a main content file (`cmain.tex`) and images. Goal: generate a styled technical book (Chinese + code / Unreal Engine animation pipeline notes) with custom chapter visuals and code listings.

## Big Picture
- Custom class `MyBook.cls` wraps and extends `ctexbook` (Chinese TeX) and transparently forwards most standard class options (font size, column mode, titlepage, side, open style) while supplying defaults when omitted.
- Visual identity: TikZ overlay chapter headers with optional full‑width background image (`\setchapterimage{<file>}`) and adaptive vertical spacing; wine/burgundy accent color `chapAccent` for numbered chapter block.
- Content leverages: Chinese typesetting (ctex), TikZ diagrams, `listings` for C++ (Unreal Engine specific keywords), `tcolorbox` custom callouts (`marker`), inline code macros `\ci` (safe) and `\cii` (highlight), and extensive explanatory sections about Unreal Engine animation threading.

## Core Files
- `MyBook.cls`: ALL layout, option forwarding, chapter header logic, code environments, colors, inline code commands, and marker box. Primary place to modify behavior; keep public surface minimal (intentionally few user macros).
- `cmain.tex`: Example book manuscript illustrating how to use the class: sets options `\documentclass[10pt,openright,oneside,CJKmath]{MyBook}` then loads extra math / table / annotation packages, sets a chapter background via `\setchapterimage{j-20}`, and contains structured sections with code/listings environments.
- `images/`: Background and illustrative images. Chapter background images are loaded with width `\paperwidth`; provide file basename without extension (graphics rules will find `.png`).

## Build Workflow
- Typical compile command (XeLaTeX/LuaLaTeX recommended for CJK + fontspec; class assumes modern engine): run `xelatex cmain.tex` (multiple passes if TOC added). If bibliography later, integrate `bibtex` / `biber` after first pass.
- Generated artifacts: `cmain.aux`, `.log`, `.synctex.gz`, `cmain.pdf` already present (indicates a successful prior compile).

## Class Option Handling Pattern
- Options in `\documentclass[...]` are first intercepted: known mutually exclusive sets (size, column, titlepage, side, open style) toggle internal flags; any unrecognized option is passed through verbatim (`DeclareOption*`). After processing, defaults are injected ONLY for categories not explicitly set (e.g., default `10pt, onecolumn, titlepage, twoside, openany`). Then `ctexbook` is loaded with aggregated options.
- When adding a new explicit option category: follow existing pattern (flag boolean + `\DeclareOption` + default injection before `\LoadClassWithOptions`).

## Chapter Header System
- Public user macro: `\setchapterimage{<basename>}` (no extension). Internals compute scaled image height and adapt vertical post‑title spacing: if an image is set, content is pushed below image bottom plus a safety gap; else a fixed spacing (`\chap@vsp@without`).
- Numbered chapters: large burgundy rounded rectangle with scaled chapter number (scalebox factor 3) positioned relative to page NW corner, responsive to one-/two-side layout (computes text area left offset). Title can gain semi‑transparent backdrop if enabled (currently backdrop disabled for numbered chapters: `\chap@title@nodeopts{}` override).
- Unnumbered chapters: centered within text width region; virtual height concept for spacing when no image (`\setschaptervirtualheight`).
- Adjustable user hooks: (documented / safe) `\setchapterimage`, `\setchapterpostcomp{}`, `\setchapnumyadjust{}`, `\setchapnumbasey{}`, `\setschaptervirtualheight{}`, `\setschapterfont{}`, `\setschapterletterspace{}`, `\setschapterlinespread{}`, `\setchaptertitlefont{}`.

## Code & Inline Highlighting
- Block code environment: `\begin{code}[<listings options>] ... \end{code}`; preconfigured for C++11+, Unreal macros, colored keywords, soft wrap with custom pre/post break glyphs (`\lstbreakpre`, `\lstbreakpost`) using hook arrows to signal wrapped lines.
- Inline safe monospace macro `\ci{...}` robust in moving arguments (uses simple `ttfamily` + blue color). Inline highlighted variant `\cii|...|` leverages `listings`; only use in normal text (not in section titles) to avoid verbatim issues.
- Extend keywords: adjust `morekeywords` list in the `\lstset` block inside `MyBook.cls` (do not redefine environment name). For additional emphasis groups, follow existing `emph=[n]{...}` pattern.

## Thematic Elements
- Accent color `wineRed` / `chapAccent` unify headings and code emphasis marks. Consistency is preferred: new tcolorbox styles should reuse these palette entries.
- Marker box environment `marker` provides an eye‑catching callout (yellow background with exclamation badge). To create a new callout style copy this pattern, change `colback/colframe` and underlay path.

## Adding Content
- Always use the class macros instead of re-implementing layout logic in chapters: e.g., call `\setchapterimage{...}` before each `\chapter` if you want a new background; after use, to revert to no background set `\setchapterimage{}`.
- Prefer `\ci` for identifiers and short code tokens inside narrative Chinese text to maintain consistent color and typeface.

## Extending the Class (Guidance for Agents)
- Keep public interface minimal; any new configurable dimension should default gracefully when unset and not break existing chapters.
- When adding new spacing logic, mirror current pattern: store user value in a length register, compute fallbacks with `\ifx\chap@image\@empty` branching.
- Maintain thread-safety commentary examples exactly (they are domain content, not class mechanics) — do NOT auto-refactor example C++ code blocks.
- If introducing new packages: ensure they are widely available in TeX Live/MiKTeX; add `\RequirePackage` near the top after existing ones; avoid conflicting geometry or font packages.

## Pitfalls / Constraints
- Do not introduce verbatim-like macros into moving arguments (section titles, TOC) — rely on `\ci` not `\cii` there.
- Avoid redefining `\chapter` directly; customization is implemented by overriding `\@makechapterhead` and `\@makeschapterhead`. Keep that structure to preserve compatibility with other packages.
- Spacing relies on overlay TikZ nodes; inserting additional vertical skips at chapter starts may break layout—adjust the existing length registers instead.

## Typical Additions Examples
- Add a new inline emphasis: define `\newcommand{\codekw}[1]{\textcolor{wineRed}{\texttt{#1}}}` and use in text. Place it in manuscript (`cmain.tex`) rather than expanding core class unless reused globally.
- New themed box: copy `marker` definition, rename, switch palette to `chapAccent` for border.

## When Unsure
- Inspect `MyBook.cls` for an existing length or macro before adding a duplicate; reuse naming convention `\chap@...` for internal, `\set...` for public setters.
- Ask if a feature belongs in content (`cmain.tex`) versus in the class (shared style). Default to content unless repeated across chapters.

---
Feedback welcome: identify unclear hooks (e.g., need chapter subtitle support?) or desired additional boxed environments so we can iterate.
