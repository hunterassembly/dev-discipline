---
summary: "Entropy-control checklist for periodic repository cleanup."
read_when:
  - Running weekly maintenance or preparing a release branch.
---

# Entropy and Garbage Collection

Use this checklist to prevent context rot in agent-driven repositories.

- [ ] Move stale active plans to `docs/plans/completed/`
- [ ] Remove outdated docs and dead references
- [ ] Prune obsolete scripts, prompts, and local one-off artifacts
- [ ] Refresh eval cases for newly shipped behavior
- [ ] Update `docs/QUALITY_SCORE.md` from latest local reports
