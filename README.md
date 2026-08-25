<p align="center">
  <img src="https://github.com/anishshobithpscollege/manipal_assignment_template/releases/download/latest/collage.png" width="92%" alt="Cover, table of contents, and a content page fanned out" />
</p>

<h1 align="center">Typst Assignment Template</h1>

<p align="center">
  University assignments in Typst, built in Docker and shipped to GitHub Releases on every push.<br />
  Cover page, roman-numbered front matter, running header and footer, and report components.
</p>

<p align="center"><sub>Preview comes from the latest release and refreshes on every build.</sub></p>

## What you get

- Typst 0.15.1 pinned in Docker with fonts baked in, so a build looks the same on your machine and in CI.
- One `config.json` for your name, registration number, subject, and logo.
- A cover page carrying the institution logo.
- Front matter in roman numerals: Table of Contents, List of Figures, List of Tables, each on its own page and listed in the contents.
- An arabic-numbered body with a running header (code, subject, assignment) and a footer (name, registration number, page).
- Components: definitions, theorems, lemmas, proofs, problems, solutions, styled tables, and figures.
- Theory and lab kinds, shown on the cover and in the header.
- Embed source files in lab reports with line numbers and line ranges, styled by the codly package (vendored into the image, so builds stay offline).
- Draw data structures — trees, heaps, lists, graphs, and sorting traces — with the typed-dsa package, also vendored for offline builds.
- CI compiles every assignment under `assignments/` at any depth and attaches the PDFs to a rolling `latest` release.

## Layout

```
config.json                  your identity and subject
template/
  assignment.typ             document shell: cover, front matter, header, footer
  components.typ             definitions, theorems, problems, and so on
  theme.typ                  colors, fonts, margins
  lib.typ                    single import surface
  assets/logo.png            institution logo
assignments/
  theory/01-example/main.typ theory component example
  lab/01-hello-world/        lab component example (main.typ + hello.c)
scripts/make_collage.py      stitches page renders into the README preview
.github/workflows/build.yml  build and release
Dockerfile                   pinned Typst plus fonts
Makefile                     local build targets
```

## Configure

Edit `config.json` once:

```json
{
  "author": "Student Name",
  "reg_no": "241234567",
  "institution": "Manipal School of Information Sciences",
  "kinds": {
    "Theory": { "course": "Subject Name", "course_code": "SUB 1001" },
    "Lab": { "course": "Subject Name Lab", "course_code": "SUB 1002" }
  },
  "logo": "/template/assets/logo.png",
  "logo_width_cm": 2.8
}
```

Every assignment reads these as defaults. Each kind under `kinds` carries its own subject name and code, so theory and lab can differ. A shared top-level `course`/`course_code` is still honored as a fallback for any kind that omits its own, and a document's `main.typ` can override either for one assignment.

## Write an assignment

Each assignment is a folder with a `main.typ`. Group them under `theory/` or `lab/`:

```typst
#import "/template/lib.typ": *

#show: assignment.with(
  title: "Your Title",
  number: "Assignment 01",
  kind: "Theory",
)

= First section

Your content.
```

`kind: "Theory"` or `kind: "Lab"` shows on the cover and in the header. Override any config value for a single document here too, for example `course: "Operating Systems"`.

### Lab: embedding source files

Keep code files next to `main.typ` and read them at the call site, so the path is relative to your assignment. The language comes from the extension.

```typst
// whole file, with line numbers
#code(read("hello.c"), file: "hello.c")

// only lines 6 to 8, real line numbers kept
#code(read("hello.c"), file: "hello.c", lines: (6, 8))
```

Pass `lang:` yourself for files with an unusual extension, e.g. `#code(read("run"), lang: "bash")`. Plain fenced blocks (```` ```c ... ``` ````) get the same line numbers and frame, since codly is on for the whole document.

The [codly](https://typst.app/universe/package/codly/) package that does this is pinned at `1.3.0` and downloaded into the Docker image at build time (see the `Dockerfile`), so compiling never touches the network. Bump the version in both the `Dockerfile` and `template/components.typ` to upgrade. To vendor any other Typst package (the way `typed-dsa` and its dependencies are), drop its `name:version` — plus any packages it imports — into the same list in the `Dockerfile`.

## Authoring tips

A few Typst habits keep the output correct and accessible:

- **Quote multi-letter math names.** Typst reads `$NPV$` as the product $N · P · V$ in italics; write `$"NPV"$` (or `$"Var"$`, `$"lcm"$`) to keep it upright. Single letters like `$n$` are fine as-is, and `gcd`, `mod`, `log` are built-in operators: `$gcd(a, b) = 1$`, `$a equiv b thick (mod n)$`.
- **Give every image `alt` text.** `#image("fig.png", alt: "what it shows", width: 3cm)` writes alternate text into the tagged PDF for screen readers. The cover logo and the example figure already do this.
- **Draw data structures with `typed-dsa`.** Add `#import "@preview/typed-dsa:0.6.0": *` to an assignment, then show a structure's `.diagram`, e.g. `bst(50, 30, 70).diagram`. The package and its `cetz` dependency are vendored into the image, so it works offline. See the Diagrams section of the example.
- **Tag the PDF with keywords** by passing `keywords: ("data-structures", "sorting")` to `assignment.with(...)`. They land in the PDF metadata so the file is searchable.
- **External links are colored automatically;** the table of contents and cross-references stay black. Just use `#link("https://…")[text]`.
- **Dates are deterministic.** The cover date and the PDF's creation date both come from `datetime.today()`, so a rebuild on the same day is byte-stable. Override per document with `date: datetime(year: 2026, month: 8, day: 10)`.

See `assignments/theory/01-example/main.typ` for each of these in context.

## Build locally

Docker is the only requirement.

```bash
make all
```

That finds every `main.typ` under `assignments/` (at any depth) and writes a PDF named after its path, so `assignments/lab/01-hello-world/main.typ` becomes `dist/lab-01-hello-world.pdf`. For a single assignment:

```bash
make build DIR=assignments/lab/01-hello-world
```

Live preview while you edit:

```bash
make watch DIR=assignments/lab/01-hello-world
```

## Releases

A push to `main` runs `.github/workflows/build.yml`, which:

1. builds the Docker image,
2. compiles every assignment to a PDF named `<reg_no>_<name>_<course>_<course_code>_<assignment_no>.pdf` from `config.json`,
3. renders the example to page PNGs and stitches them into `collage.png`,
4. replaces the `latest` release with the PDFs and the collage.

Grab the current PDFs from the [latest release](https://github.com/anishshobithpscollege/manipal_assignment_template/releases/latest). The preview images above read from that same release, so they follow the newest build.

## Use as a template

Create a new subject repo with **Use this template**. On its first push, the
`Bootstrap from template` workflow fills in the README, installs the slim build
and monthly template-sync workflows, and removes the template-only files.

That workflow rewrites files under `.github/workflows/`, which GitHub forbids the
default `GITHUB_TOKEN` from doing. Add a `BOOTSTRAP_TOKEN` secret holding a
personal access token with **Contents** and **Workflows** write access —
set it as an **organization** secret so every generated repo inherits it, and
bootstrap runs with no per-repo setup. Without it, the first run fails fast with
a message saying so.

## License

See [LICENSE](LICENSE).
