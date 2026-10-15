# AI-Use Disclosure — MAF900 Assessment 3, Part 3

Per the Part 3 brief, generative AI may be used for coding, debugging,
documentation and analytical support, with the emphasis on methodological
judgement, collaborative review, transparency and reproducibility. This
disclosure records how AI was used in this repository.

## AI assistance

The group used Anthropic Claude as a coding and documentation assistant
across Parts 1-3: drafting and debugging R scripts from our written
specifications, helping to structure documentation (README, decision-record
and review templates, the comparison-report skeleton), and supporting
repository organisation. Commits with substantial AI-drafted content carry a
Co-Authored-By attribution line in the commit message, so the extent of
assistance is visible in the repository history itself.

## The group's own work

- The selection of the two decision points, the design of Alternatives A
  and B, and the ex-ante expected implications come from our Part 1 analyses
  and the Part 2 strategy document.
- The methodological choices recorded in `decisions/decision1.md` and
  `decision2.md` — including the selection of the strict rule (A) for
  Decision 1 and the reconstructed NYSE index (B) for Decision 2 — are the
  group's own, made after comparing the implemented alternatives.
- All pipeline runs against WRDS/CRSP data, and the verification of outputs
  against the patterns documented in Fama and MacBeth (1973), were performed
  by the group on our own machines. No WRDS credentials or licensed CRSP
  data were provided to AI tools or committed to this repository.
- Each member is responsible for the alternatives and reviews carrying their
  name and for the final submitted work.

Signed: Qixin (Sheena) Chen; Jimmy Zhang — October 2026
