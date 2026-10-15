# Decision 2 — Table 2 market-return proxy

**Final decision: Alternative B — Sheena's reconstructed NYSE equal-weighted market proxy**

## Question

Fama and MacBeth use Fisher's Arithmetic Index, an equal-weighted average of
returns on NYSE-listed stocks. The historical Fisher series is not distributed
as such in the contemporary CRSP workflow, so a modern replication needs a
market-return proxy.

## Feasibility assessment

| Criterion | Alternative A — Jimmy | Alternative B — Sheena |
|---|---|---|
| Technically feasible | YES | YES |
| Simple to reproduce | Very high | High |
| Researcher-defined universe | No | Yes, but explicitly coded |
| Constant NYSE-only concept | Not guaranteed | YES |
| Direct match to Fisher definition | Partial | Strong |
| Constituent-count diagnostic | Not needed | `n_stocks` retained each month |
| Final use | Retained as benchmark | SELECTED |

## Why Alternative B is selected

Jimmy's Alternative A is the simpler implementation: it directly uses CRSP's
published equal-weighted market return. It is easy for another researcher to
reproduce and avoids researcher-defined security filters. It is therefore a
valid benchmark.

The problem is conceptual rather than technical. The maintained CRSP market
index does not guarantee the same constant NYSE-only universe described by
Fama and MacBeth over the full sample. That creates a systematic deviation
from the original market proxy.

Sheena's Alternative B reconstructs the market return each month from all
date-valid NYSE common stocks in the panel. The universe rule is transparent
(`exchcd = 1`, `shrcd` 10/11 through the date-valid names history), the index
does not depend on Decision 1 eligibility, and no arbitrary minimum
constituent filter is imposed. This more directly implements Fisher's stated
NYSE equal-weighted concept.

For replication fidelity, that advantage outweighs the extra coding needed
to reconstruct the index. Alternative B is therefore selected.

## Expected difference

The two Rm series should be similar when the CRSP maintained universe is
effectively NYSE-only and may diverge when its exchange coverage differs from
the reconstructed NYSE-only universe. The proxy can change beta levels and
ranks, so formation betas and portfolio memberships are re-estimated under
each proxy rather than held fixed.

The comparison script writes:

- `output/tables/decision2_market_series.csv`
- `output/tables/decision2_market_summary.csv`
- `output/tables/table2_altA.csv`
- `output/tables/table2_altB.csv`
- `output/tables/decision2_beta_comparison.csv`

## Review conclusion

- Sheena's review of Jimmy Alternative A: technically feasible and useful as a
  transparent benchmark, but less faithful to the original NYSE-only concept.
- Jimmy's review of Sheena Alternative B: technically feasible and preferred
  for final replication because its universe definition directly matches the
  historical description.

## Final implementation

The agreed market proxy is copied into:

`code/final/02_agreed_market_proxy.R`

The final workflow does not depend on either decision-development folder.
