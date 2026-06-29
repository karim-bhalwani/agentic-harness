# Tiering Thresholds

| Tier       | Last Access                            | Risk Level              | Action                                                                                        |
| :--------- | :------------------------------------- | :---------------------- | :-------------------------------------------------------------------------------------------- |
| Ghost      | Strictly >18 months                    | Low (safe to deprecate) | Archive and remove                                                                            |
| Cold       | Strictly >12 months, ≤18 months        | Medium                  | Flag for review, contact owners                                                               |
| Cool       | Strictly >6 months, ≤12 months         | Medium-High             | Monitor, investigate usage                                                                    |
| Active     | ≤6 months (including exactly 6 months) | N/A                     | Keep, optimize if needed                                                                      |
| Unobserved | No log entries in analysis window      | High (manual review)    | Flag for manual review; absence of logs may indicate log coverage gap, not genuine inactivity |

**Boundary rule**: Use strict greater-than for upper bounds. An object last accessed exactly 6 months ago is Active. An object last accessed exactly 12 months ago is Cold. An object last accessed exactly 18 months ago is Cold (not Ghost). Ghost requires strictly more than 18 months with no access.
