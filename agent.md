# Autonomous Agent Rules / Instructions

This file instructs AI coding assistants (such as Antigravity) on core principles to adhere to when working on this repository.

1. **Propagation of Code Changes to Documentation**:
   - If any business logic, API endpoint, database schema, or controller behavior is modified, and a corresponding documentation file exists (e.g. under `docs/` such as `docs/balance_update_actions.md` or `docs/business_logic_evaluation.md`), you **MUST** immediately propagate these updates to the documentation so that it remains a source of truth.

2. **Self-Documenting & Descriptive Comments**:
   - Always comment any complex, non-obvious, or potentially ambiguous choices in implementation.
   - For instance, if cashBalance is deliberately bypassed in a handler because it's a virtual bookkeeping entry, document that directly inside the code to prevent future developers from introducing a regression.
   - Similarly, document why mathematical helper functions (like `round2`) are used to override native Javascript floating-point math operators.
