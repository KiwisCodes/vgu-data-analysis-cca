# Compulsory Elective 1 (M 25.6): Data Analysis in High Dimensions
**Vietnamese-German University (VGU)** • Winter Semester 2026–2027  
**Instructor:** Prof. Dr. Christina Andersson • **Credits:** 5 ECTS  
**Group Topic:** **Canonical Correlation Analysis (CCA)**  
**GitHub Repository:** [`https://github.com/KiwisCodes/vgu-data-analysis-cca`](https://github.com/KiwisCodes/vgu-data-analysis-cca)

---

## 📌 Project Overview

This repository contains the empirical survey data, preprocessing pipeline, statistical modeling in **R**, presentation slides, and final written report for our research project in **Data Analysis in High Dimensions**.

* **Selected Multivariate Method:** **Canonical Correlation Analysis (CCA)** (Slides 190–232).
* **Research Investigation:** Investigating the multivariate relationship between **University Student Lifestyle & Tech Habits (Set $X$)** and **Academic Performance & Psychological Well-Being (Set $Y$)**.
* **Empirical Data:** Primary self-collected survey data from university students ($N = 107$ valid responses).
* **Examination Policy:** **No written exam!** The final grade is evaluated 100% on the **Oral Presentation (Nov 16)** and the **Final Written Report (Nov 25)**.

---

## 📅 Critical Dates & Assessment Criteria

| Date | Event / Deliverable | Requirements & Constraints |
| :--- | :--- | :--- |
| **Nov 4, 2026** | **Group & Topic Registration** | Registered group on Moodle (Topic: *Canonical Correlation Analysis*). |
| **Nov 16, 2026** | **Oral Presentation** (VGU Campus) | **3 to 5 minutes per member**. Covers method theory, survey methodology, R results, and critique. |
| **Nov 25, 2026** | **Final Report Submission** | **2 to 3 pages per member** (ONE consolidated group report: 8–12 pages total for 4 members). Must include complete **R code in the appendix**. |

---

## 🎯 Theoretical Framework: Canonical Correlation Analysis (CCA)

Canonical Correlation Analysis (Chapter 6, Slides 190–232) investigates the relationship between **two multidimensional sets of variables** measured on the same individuals:
* **Predictor Battery $\mathbf{X}$ ($p = 7$ variables):** Daily lifestyle, digital screen habits, social study patterns, and AI reliance.
* **Criterion Battery $\mathbf{Y}$ ($q = 5$ variables):** Academic success, course failure history, perceived stress, and self-esteem.

### 1. Mathematical Formulation
Instead of calculating $7 \times 5 = 35$ separate pairwise correlations (which inflates Type I error and ignores multivariate interdependencies), CCA derives linear combinations called **Canonical Variates**:
$$U_1 = a_1 X_1 + a_2 X_2 + \dots + a_p X_p = \mathbf{a}'\mathbf{X}$$
$$V_1 = b_1 Y_1 + b_2 Y_2 + \dots + b_q Y_q = \mathbf{b}'\mathbf{Y}$$

The weight vectors $\mathbf{a}$ and $\mathbf{b}$ are chosen to maximize the Pearson correlation:
$$\rho^*_1 = \mathrm{Corr}(U_1, V_1) = \frac{\mathbf{a}' \mathbf{\Sigma}_{xy} \mathbf{b}}{\sqrt{(\mathbf{a}' \mathbf{\Sigma}_{xx} \mathbf{a})(\mathbf{b}' \mathbf{\Sigma}_{yy} \mathbf{b})}}$$

### 2. Constraints & Orthogonality
To ensure a unique mathematical solution via eigenvalue decomposition:
1. **Unit Variance:** $\mathrm{Var}(U_i) = \mathbf{a}_i'\mathbf{\Sigma}_{xx}\mathbf{a}_i = 1$ and $\mathrm{Var}(V_i) = \mathbf{b}_i'\mathbf{\Sigma}_{yy}\mathbf{b}_i = 1$.
2. **Orthogonality:** Successive pairs $(U_2, V_2), \dots, (U_k, V_k)$ capture the maximum remaining correlation subject to being completely uncorrelated with previous pairs:
   $$\mathrm{Cov}(U_i, U_j) = 0, \quad \mathrm{Cov}(V_i, V_j) = 0, \quad \mathrm{Cov}(U_i, V_j) = 0 \quad (i \ne j)$$
   *Total canonical pairs:* $k = \min(p, q) = \min(7, 5) = \mathbf{5\text{ pairs}}$.

### 3. Statistical Significance Testing (Wilks' Lambda $\Lambda$)
We test whether canonical correlations are statistically greater than zero using Wilks' Lambda (Slides 222–231):
$$\Lambda_1 = \prod_{i=1}^k (1 - \rho_i^{*2})$$
* **Step 1:** $H_0: \rho_1^* = \rho_2^* = \dots = \rho_k^* = 0$ (Tests whether the two batteries are independent).
* **Step 2:** $H_0: \rho_2^* = \dots = \rho_k^* = 0$ (Tests whether remaining dimensions are significant).

---

## 📊 The Finalized Survey Instrument ($N = 107$)

Our empirical dataset was collected from $108$ respondents across university programs. After filtering out 1 obvious troll submission (`Major = "ăn tàn phá hoại"`, Sleep = 0h, Workout = 8h, Failed = 19), our clean sample is **$N = 107$ valid students**.

```mermaid
flowchart LR
    subgraph Battery_X ["Set X: Lifestyle & Tech Habits (p = 7)"]
        X1["x_sleep_hours (3–12h)"]
        X2["x_phone_bed (0–8h)"]
        X3["x_sitting_hours (2–16h)"]
        X4["x_workout_hours (0–4h)"]
        X5["x_friends_hangout (0–30)"]
        X6["x_friends_study (0–10)"]
        X7["x_ai_reliance (Scale 1–7)"]
    end

    subgraph CCA_Engine ["Canonical Variates (cancor / cc)"]
        U1["U1 = a'X (Lifestyle Variate)"]
        V1["V1 = b'Y (Academic & Well-being Variate)"]
    end

    subgraph Battery_Y ["Set Y: Academic & Well-being Outcomes (q = 5)"]
        Y1["y_gpa_pct (50–100%)"]
        Y2["y_academic_rank (Scale 1–4)"]
        Y3["y_failed_courses (0–5)"]
        Y4["y_total_stress (PSS-4: 0–16)"]
        Y5["y_self_esteem (Scale 1–7)"]
    end

    Battery_X ==>|"a weights"| U1
    U1 <===>|"Canonical Correlation Rc1"| V1
    V1 <==| "b weights"| Battery_Y
```

### Detailed Variables Breakdown:

| Variable | Survey Question & Construct | Scale / Units | Preprocessing & Transformation |
| :--- | :--- | :---: | :--- |
| **`x_sleep_hours`** | Typical daily sleep duration | Hours (3–12) | Continuous numeric. |
| **`x_phone_bed`** | Bedtime phone usage for entertainment | Hours (0–8) | Continuous numeric. |
| **`x_sitting_hours`** | Typical sedentary sitting time | Hours (2–16) | Continuous numeric. |
| **`x_workout_hours`** | Daily exercise and sports time | Hours (0–4) | Continuous numeric. |
| **`x_friends_hangout`** | Number of friends usually hanging out with | Count (0–30) | Discrete count. |
| **`x_friends_study`** | Number of friends usually studying with | Count (0–10) | Discrete count (0 = study alone). |
| **`x_ai_reliance`** | AI control level in university study/work | Ordinal (1–7) | Exact 1:1 mapping from survey options (1 = No AI to 7 = Max AI autonomy). |
| **`y_gpa_pct`** | Cumulative Academic GPA | Percentage (50–100%) | Normalized across 4-point, 10-point, and German scales. |
| **`y_academic_rank`** | Estimated academic rank among cohort | Ordinal (1–4) | Top 10% = 4, Top 30% = 3, Top 50% = 2, Top 70% = 1, Other = 2.5. |
| **`y_failed_courses`** | Number of courses failed on first attempt | Count (0–5) | Discrete count. |
| **`y_total_stress`** | Cohen Perceived Stress Scale (PSS-4) | Score (0–16) | Sum of 4 items with items 18 & 19 **reverse-coded** ($Q_{17} + (4 - Q_{18}) + (4 - Q_{19}) + Q_{20}$). |
| **`y_self_esteem`** | Single-Item Self-Esteem Scale (SISE) | Rating (1–7) | Likert scale (1 = Not true of me to 7 = Very true). |

---

## 💻 R Preprocessing Pipeline (`01_preprocess_data.R`)

The preprocessing script cleans the raw Excel file, performs exact string encodings, reverse-scores validated psychological scales, and exports two datasets:

```r
# Key transformations in 01_preprocess_data.R

# 1. Exact sentence dictionary for AI reliance
ai_reliance_map <- c(
  "I don’t use AI for my work or study." = 1,
  "Less than 5% – I give my idea to the AI and validate its execution" = 1,
  "I do the idea and the work; AI only helps with small things (explaining, grammar, bugs)." = 2,
  "25% – I and the AI work on the idea and execution together" = 3,
  "I do the idea; AI does the work; I check it." = 4,
  "AI and I share the idea; AI does the work; I check it." = 5,
  "AI does the idea and the work; I check the idea and the details." = 6,
  "50% – AI automates everything (from idea to execution), I check its idea and execution" = 6,
  "AI does the idea and the work; I check the idea only." = 7
)
X$x_ai_reliance <- unname(ai_reliance_map[df[[10]]])

# 2. GPA Scale Normalization to 0-100%
# 4-point: (GPA / 4) * 100
# 10-point: (GPA / 10) * 100
# German: (4.0 - GPA) / 3.0 * 50 + 50 (1.0 = 100%, 4.0 = 50%)

# 3. PSS-4 Reverse-Coding
total_stress <- unname(stress_map[df[[17]]]) + 
                (4 - unname(stress_map[df[[18]]])) + 
                (4 - unname(stress_map[df[[19]]])) + 
                unname(stress_map[df[[20]]])
```

### Outputs Produced:
1. **`survey_clean_unstandardized.csv`**: Contains raw real-world units (hours, percentage, raw counts). Used for **demographic summary tables, histograms, and presentation boxplots**.
2. **`survey_clean_standardized.csv`**: Contains standardized $z$-scores ($\mu = 0, \sigma = 1$). Fed directly into **`cancor(X, Y)`** for mathematical modeling.

---

## 📂 Repository Workspace Structure

```text
vgu-data-analysis-cca/
├── 01_preprocess_data.R                                        # Data cleaning & validation script
├── README.md                                                   # Complete project documentation
├── Responses – Student Lifestyle & Academic Performance Survey.xlsx # Raw survey responses (N = 108)
├── survey_clean_unstandardized.csv                             # Cleaned data in natural units (N = 107)
├── survey_clean_standardized.csv                               # Cleaned standardized data (z-scores)
└── docs/                                                       # Official course materials
    ├── Course Description-3.pdf                               # Module syllabus & competencies
    ├── readmefromprofessor.pdf                                 # Professor's project & exam guidelines
    └── vorlesung-1.pdf                                         # Lecture deck (CCA: Slides 190–232)
```

---

## 🚀 Execution & Next Steps

1. **Run Preprocessing Script in RStudio:**
   ```bash
   Rscript 01_preprocess_data.R
   ```
2. **Phase 2 (Upcoming):**
   * Compute Canonical Correlations ($R_c$) and Wilks' Lambda tests.
   * Calculate Canonical Loadings (structure coefficients) to see which habits drive academic outcomes.
   * Generate canonical variate scatterplots ($U_1$ vs. $V_1$) for the **Nov 16 presentation slides**.
   * Compile the **Nov 25 Final Report** (8–12 pages) with the R code appendix.
