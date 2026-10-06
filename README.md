# Fama & MacBeth (1973) Replication

MAF900 Advanced Data Methods — Assessment 3 Part 3  
Group: Qixin (Sheena) Chen and Yuyao (Jimmy) Zhang  
Repository: https://github.com/Harumeow-summer/MAF900-Advanced-Data-Methods-A3-Part-3-Group-Replication-

#### Update note: 05 Oct 2026

 This repository will implement the Group Replication Strategy submitted in Part 2. Code, alternative implementations, reciprocal reviews, decision logs and final replication outputs will be added progressively during Part 3.

## Current milestone 6 Oct 2026 Sheena

This first stage contains the common replication base plus Sheena's two assigned implementations:

- DP1 Alternative A: strict valid-return rule;
- DP2 Alternative B: reconstructed NYSE equal-weighted market proxy.

## Part 2 decision allocation

| Decision point | Alternative A | Alternative B |
|---|---|---|
| DP1 — data-availability rule | Sheena | Jimmy |
| DP2 — market-return proxy | Jimmy | Sheena |

## Data

WRDS/CRSP raw and processed data are licensed and excluded from GitHub.
Create `config/wrds_credentials.R` locally from the template.

## Reproducibility

Common scripts live in `code/common/`. Alternative-development folders are
kept separate from the final agreed replication.
