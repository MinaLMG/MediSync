/**
 * ============================================================
 * Revenue–Loss Model Documentation
 * ============================================================
 *
 * This file documents the mathematical model used to calculate:
 *  - Revenue Ratio (R)
 *  - Loss Ratio (y)
 *  - Sildenafil Ratio (z)
 *
 * The model supports both:
 *  - Single-row calculations
 *  - Multi-row (aggregated) calculations
 *
 * All formulas below are written explicitly so the logic is
 * transparent, auditable, and easy to port to other languages.
 */

/* ============================================================
 * 1. Variable Definitions
 * ============================================================
 *
 * x      : Sales volume (row-specific)
 * R      : Revenue ratio
 * y      : Loss ratio (row-specific)
 * alpha  : Sildenafil buying/sale ratio
 * gamma  : Pharmacy sale ratio (row-specific)
 * beta   : Minimum sale
 * z      : Sildenafil ratio
 *
 * NOTE:
 * - x, gamma, y may vary per row
 * - alpha, beta, z are assumed global unless stated otherwise
 */

/* ============================================================
 * 2. Base Equation (Single Row)
 * ============================================================
 *
 * For a single row:
 *
 *   R * x
 *   = alpha * (1 - gamma) * z * x
 *   + (0.1 / (1 - beta)) * (1 - z) * (1 - gamma) * x
 *   - y * x
 *
 * Dividing both sides by x (assuming x !== 0):
 *
 *   R
 *   = alpha * (1 - gamma) * z
 *   + (0.1 / (1 - beta)) * (1 - z) * (1 - gamma)
 *   - y
 */

/* ============================================================
 * 3. Single-Row Closed-Form Solutions
 * ============================================================
 */

/**
 * 3.1 Solve for Loss Ratio (y)
 *
 *   y
 *   = (1 - gamma) * [ alpha * z + (0.1 / (1 - beta)) * (1 - z) ]
 *   - R
 */
function calculateY({ R, alpha, beta, gamma, z }) {
  return (1 - gamma) *
         (alpha * z + (0.1 / (1 - beta)) * (1 - z)) -
         R;
}

/**
 * 3.2 Solve for Revenue Ratio (R)
 *
 *   R
 *   = (1 - gamma) * [ alpha * z + (0.1 / (1 - beta)) * (1 - z) ]
 *   - y
 */
function calculateR({ y, alpha, beta, gamma, z }) {
  return (1 - gamma) *
         (alpha * z + (0.1 / (1 - beta)) * (1 - z)) -
         y;
}

/**
 * 3.3 Solve for Sildenafil Ratio (z)
 *
 * Starting from:
 *
 *   R + y
 *   = (1 - gamma) * [ alpha * z + (0.1 / (1 - beta)) * (1 - z) ]
 *
 * Solving for z:
 *
 *   z
 *   = ( (R + y) / (1 - gamma) - (0.1 / (1 - beta)) )
 *     / ( alpha - (0.1 / (1 - beta)) )
 */
function calculateZ({ R, y, alpha, beta, gamma }) {
  return (
    (R + y) / (1 - gamma) -
    (0.1 / (1 - beta))
  ) / (
    alpha - (0.1 / (1 - beta))
  );
}

/* ============================================================
 * 4. Multi-Row Generalization
 * ============================================================
 *
 * For n rows, where x_i, gamma_i, and y_i vary by row.
 *
 * Define aggregates:
 *
 *   X = Σ x_i
 *   A = Σ [ x_i * (1 - gamma_i) ]
 *   B = Σ [ x_i * y_i ]
 *
 * These aggregates fully summarize the dataset.
 */

/**
 * Compute aggregates X, A, B from row data
 */
function computeAggregates(rows) {
  let X = 0;
  let A = 0;
  let B = 0;

  for (const row of rows) {
    const { x, gamma, y } = row;
    X += x;
    A += x * (1 - gamma);
    B += x * y;
  }

  return { X, A, B };
}

/* ============================================================
 * 5. Multi-Row Revenue Formula
 * ============================================================
 *
 *   R * X
 *   = A * [ z * alpha + (1 - z) * (0.1 / (1 - beta)) ]
 *   - B
 *
 * Solving for R:
 *
 *   R
 *   = ( A * [ z * alpha + (1 - z) * (0.1 / (1 - beta)) ] - B ) / X
 */
function calculateMultiRowR({ A, B, X, alpha, beta, z }) {
  return (
    A * (z * alpha + (1 - z) * (0.1 / (1 - beta))) - B
  ) / X;
}

/* ============================================================
 * 6. Multi-Row Sildenafil Ratio (z)
 * ============================================================
 *
 * Solving the multi-row equation for z:
 *
 *   z
 *   = ( (R * X + B) / A - (0.1 / (1 - beta)) )
 *     / ( alpha - (0.1 / (1 - beta)) )
 */
function calculateMultiRowZ({ R, A, B, X, alpha, beta }) {
  return (
    (R * X + B) / A -
    (0.1 / (1 - beta))
  ) / (
    alpha - (0.1 / (1 - beta))
  );
}

/* ============================================================
 * 7. Validity & Safety Checks
 * ============================================================
 *
 * The following conditions must hold:
 *
 *   x !== 0
 *   gamma !== 1
 *   beta !== 1
 *   alpha !== (0.1 / (1 - beta))
 *
 * If z represents a ratio, it should be bounded:
 *
 *   z ∈ [0, 1]
 */
function clampZ(z) {
  return Math.max(0, Math.min(1, z));
}

/* ============================================================
 * End of File
 * ============================================================
 */
