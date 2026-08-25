# 2026 Manipal Computer Networks

Coursework for this subject, written in [Typst](https://typst.app) and built in Docker.

## Downloads

Every push to `main` compiles each assignment to a PDF and attaches it to the [latest release](../../releases/latest). Files are named `<reg_no>_<name>_<course>_<course_code>_<assignment_no>.pdf` from `config.json`. Grab the whole set from the [release](../../releases/latest), or pick one below.

### Theory

<!-- THEORY:START -->

_None yet. Add one under `assignments/theory/`._

<!-- THEORY:END -->

### Lab

<!-- LAB:START -->

| # | Assignment | Download |
| :-- | :-- | :-- |
| 02 | Understanding the OSI Model | [PDF](../../releases/download/latest/261100690032_Anish_Shobith_P_S_Computer_Networks_and_Security_Lab_CYE_5154_02.pdf) |

<!-- LAB:END -->

## Set your identity

Edit `config.json` once. The PDF filenames, cover, and header all read from it.

```json
{
  "author": "Student Name",
  "reg_no": "241234567",
  "kinds": {
    "Theory": { "course": "Subject Name", "course_code": "SUB 1001" },
    "Lab": { "course": "Subject Name Lab", "course_code": "SUB 1002" }
  }
}
```

Each kind under `kinds` carries its own name and code, so lab and theory can differ. A shared top-level `course`/`course_code` is also honored as a fallback for any kind that omits its own. A document's `main.typ` overrides either for one assignment.

## Add an assignment

Each assignment is a folder with a `main.typ`, under `assignments/theory/` or `assignments/lab/`. Name the folder `NN-slug`, e.g. `02-substitution-cipher`. The leading number becomes the assignment number in the filename and the table above.

```typst
#import "/template/lib.typ": *

#show: assignment.with(
  title: "Your Title",
  number: "Assignment 02",
  kind: "Theory",
)

= First section

Your content.
```

Set `kind` to `"Theory"` or `"Lab"`. It shows on the cover and header. Override any `config.json` value for a single document here too, e.g. `course: "Cryptology"`.

## Build locally

Docker is the only requirement.

```bash
make all
```

PDFs land in `dist/`. For a single assignment:

```bash
make build DIR=assignments/theory/02-substitution-cipher
make watch DIR=assignments/theory/02-substitution-cipher
```

## License

See [LICENSE](LICENSE).

---

<sub>Generated from the [anishshobithpscollege/manipal_assignment_template](https://github.com/anishshobithpscollege/manipal_assignment_template) template. A monthly sync PR keeps the shared Typst template, `Dockerfile`, and `Makefile` current.</sub>
