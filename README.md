# Compulsory Elective 1 (M 25.6): Data Analysis in High Dimensions
**Vietnamese-German University (VGU)** • Winter Semester 2026–2027  
**Instructor:** Prof. Dr. Christina Andersson • **Credits:** 5 ECTS  

---

## 📌 Executive Summary & Group Mission

This repository contains the coursework, empirical survey data, statistical code in **R**, presentation slides, and the final written report for **Compulsory Elective 1: Data Analysis in High Dimensions**.

* **Selected Group Topic:** **Canonical Correlation Analysis (CCA)**
* **Project Format:** Empirical survey design & data collection among university peers $\rightarrow$ Multivariate statistical modeling in **R** $\rightarrow$ Oral defense & written report.
* **Examination Policy:** **No written exam!** The module grade is determined $100\%$ by the **Group Presentation ($30\text{–}40\%$)** and the **Final Written Report ($60\text{–}70\%$)**.

---

## 📅 Critical Dates & Milestones

| Date | Milestone / Event | Requirements & Constraints |
| :--- | :--- | :--- |
| **Nov 4, 2026** | **Group & Topic Registration** | Register group on Moodle (max 4 members). Selected topic: *Canonical Correlation Analysis*. |
| **Nov 16, 2026** | **Oral Presentation** (On-campus at VGU) | **3 to 5 minutes per member**. Presentation on method fundamentals, strengths/weaknesses, survey design, and empirical findings. |
| **Nov 25, 2026** | **Final Report Submission** | **2 to 3 pages per member** (Consolidated into **ONE** single group report: e.g., 6–9 pages for 3 members, 8–12 pages for 4 members). Must include complete **R code in the appendix**. |

---

## 📚 Course Materials & Context in This Workspace

| File | Description & Role |
| :--- | :--- |
| [`Course Description-3.pdf`](file:///Users/apple/VGU/Year%204%202026-2027/Compulsory%20Elective%201%20-%20Prof.Dr.%20Christina%20Andersson/Course%20Description-3.pdf) | Official syllabus outlining theoretical learning outcomes and covered multivariate methods (PCA, PLS, Logistic Regression, Cluster Analysis, Discriminant Analysis, Canonical Covariate/Correlation Analysis). |
| [`readmefromprofessor.pdf`](file:///Users/apple/VGU/Year%204%202026-2027/Compulsory%20Elective%201%20-%20Prof.Dr.%20Christina%20Andersson/readmefromprofessor.pdf) | Official assignment requirements from Prof. Dr. Christina Andersson detailing report formatting, page quotas, oral presentation length, deadline dates, and R code requirements. |
| [`vorlesung-1.pdf`](file:///Users/apple/VGU/Year%204%202026-2027/Compulsory%20Elective%201%20-%20Prof.Dr.%20Christina%20Andersson/vorlesung-1.pdf) | Complete 232-slide lecture deck. **Chapter 6 (Slides 190–232)** is dedicated entirely to **Canonical Correlation Analysis (CCA)**, including mathematical derivations, paired-variable examples, and interpretation guidelines. |

---

## 🎯 Topic Deep-Dive: Canonical Correlation Analysis (CCA)

### 1. Conceptual Overview
Canonical Correlation Analysis (CCA) is a generalized multivariate statistical technique designed to investigate the relationship between **two multidimensional sets of variables** measured on the same subjects:
* **Set $X$ (Predictor / Baseline Battery):** $p$ variables ($X_1, X_2, \dots, X_p$)
* **Set $Y$ (Criterion / Outcome Battery):** $q$ variables ($Y_1, Y_2, \dots, Y_q$)

Unlike standard multiple regression (which models a single dependent variable $Y$ from multiple $X$'s) or PCA (which summarizes variance within a single set $X$), CCA determines pairs of synthetic linear combinations (canonical variates):
$$U_1 = a_1 X_1 + a_2 X_2 + \dots + a_p X_p = \mathbf{a}'\mathbf{X}$$
$$V_1 = b_1 Y_1 + b_2 Y_2 + \dots + b_q Y_q = \mathbf{b}'\mathbf{Y}$$
such that the Pearson correlation $\rho = \mathrm{Corr}(U_1, V_1)$ is maximized. Subsequent canonical pairs $(U_2, V_2), \dots, (U_k, V_k)$ are extracted to maximize remaining correlation subject to being orthogonal (uncorrelated) to previous pairs.

### 2. Why CCA Matches Our Survey Project
Prof. Andersson specifically instructed:
> *"A practical part where you collect your own data (not only downloaded from internet!!! Make for example a survey among your colleagues!) and analyze it with your method."*

Surveys are naturally structured into paired psychological, behavioral, or academic constructs. CCA allows us to answer questions like:
* *"How does a student's lifestyle and habit profile (Set $X$) correlate with their mental well-being and academic performance (Set $Y$)?"*
* Instead of running dozens of separate pairwise regressions or correlations (which inflate Type I error), CCA synthesizes the entire relationship into 1–2 interpretable dimensions.

---

## 📋 Empirical Survey Formulation & Strategy

To perform CCA, our survey questionnaire **must** measure two distinct multi-item quantitative/Likert-scale batteries from each participant ($N \ge 60\text{--}100$ recommended for robust estimates).

### Potential Survey Concepts:
1. **Option A (Recommended: Student Lifestyle & Study Habits vs. Academic & Cognitive Health)**
   * **Set $X$ (Lifestyle / Input Factors):**
     * Average nightly sleep (hours)
     * Weekly self-study hours
     * Daily recreational screen/social media time (hours)
     * Physical exercise frequency (days/week)
     * Caffeine intake (cups/day)
   * **Set $Y$ (Academic & Well-being Outcomes):**
     * Current Cumulative GPA
     * Perceived academic stress / burnout score (1–5 Likert scale)
     * Daily cognitive fatigue / tiredness score (1–5 Likert scale)
     * Subjective focus / attention span rating (1–5 Likert scale)

2. **Option B (AI & Study Tech Adoption vs. Learning Confidence & Productivity)**
   * **Set $X$ (AI Tool Usage Profile):** Frequency of ChatGPT/Claude/Copilot use for coding, writing, debugging, and ideation.
   * **Set $Y$ (Perceived Academic Efficacy):** Problem-solving autonomy, grade satisfaction, time saved, critical thinking anxiety.

3. **Option C (Social Media Consumption vs. Social Connectedness & Emotional Mood)**
   * **Set $X$ (Platform usage breakdown):** TikTok/Reels hours, Instagram hours, messaging hours.
   * **Set $Y$ (Psychological indices):** Fear of Missing Out (FoMO), perceived loneliness, subjective happiness.

---

## 💻 Data Analysis & R Implementation Pipeline

The professor requires all analytical code to be implemented in **R** and attached as an appendix.

### Analytical Pipeline:
1. **Data Cleaning & Preprocessing:**
   * Checking missing values, removing incomplete submissions.
   * Standardizing variables ($\mu = 0, \sigma = 1$) to eliminate scale discrepancy.
2. **Assumption Testing:**
   * Multivariate normality checks (Shapiro-Wilk / Mardia test).
   * Multicollinearity within Set $X$ and Set $Y$ (correlation matrices and VIF).
   * Linearity checks (scatterplot matrices).
3. **CCA Computation:**
   * Running base R `cancor()` or specialized libraries (`yacca`, `CCA`, `candisc`).
4. **Statistical Significance & Interpretation:**
   * **Wilks' Lambda ($\Lambda$)** tests to evaluate statistical significance of canonical dimensions.
   * **Canonical Correlation Coefficients ($R_c$)** and eigenvalues.
   * **Standardized Canonical Coefficients:** Determine the relative weight of each variable in forming variates $U$ and $V$.
   * **Canonical Loadings (Structure Coefficients):** Correlation between original variables and their respective canonical variates.
   * **Redundancy Analysis:** Calculating the percentage of variance in Set $Y$ explained by the canonical variate of Set $X$.

---

## 📝 Required Deliverables & Specifications

### 1. Oral Presentation (Nov 16, 2026)
* **Venue:** VGU Campus.
* **Duration:** Strict **3 to 5 minutes per person** (e.g. 12–20 minutes total for 4 members).
* **Suggested Role Division:**
  * *Speaker 1:* Motivation, Problem Statement, Survey Design & Demographics.
  * *Speaker 2:* Mathematical Framework of CCA, Objective Function, Eigenvalue Formulation.
  * *Speaker 3:* R Implementation, Canonical Variates, Wilks' Lambda, Statistical Results.
  * *Speaker 4:* Practical Interpretation, Method Strengths/Weaknesses, Critical Reflection & Q&A.

### 2. Written Group Report (Nov 25, 2026)
* **Format:** **ONE single report per group**.
* **Page Limit:** **2 to 3 pages per member** (excluding title page, references, and code appendix).
  * 3 members $\rightarrow$ 6 to 9 pages.
  * 4 members $\rightarrow$ 8 to 12 pages.
* **Mandatory Report Structure:**
  1. **Introduction & Objective:** Problem context and research hypothesis.
  2. **Theoretical Foundation of CCA:** Mathematical formulation, objective function, canonical variates, derivation, and assumptions.
  3. **Strengths & Weaknesses:** Comparative critique of CCA (e.g., vs. Multiple Regression, PCA, PLS).
  4. **Empirical Survey & Methodology:** Target sample, question design, questionnaire administration, data preprocessing.
  5. **Empirical Results & Interpretation:** Canonical correlations, Wilks' Lambda test, canonical loadings, redundancy analysis, domain insights.
  6. **Conclusion & Discussion:** Summary of findings, limitations of survey sample size/sampling bias.
  7. **References:** Academic citations (Johnson & Wichern, Hastie et al., etc.).
  8. **Appendix:** Fully reproducible **R Script** used for the analysis.

---

## 📂 Repository Workspace Structure

```text
├── Course Description-3.pdf    # Official VGU module description
├── readmefromprofessor.pdf     # Examination guidelines & instructions
├── vorlesung-1.pdf             # Complete lecture slides (CCA in Ch. 6, slides 190–232)
├── README.md                   # Project context, roadmap, and instructions
│
├── survey/                     # Survey design, question bank & Google Forms schema
│   ├── questionnaire.md        # Survey questions, Likert scales, and variable mappings
│   └── form_link.txt           # Live Google Forms / Microsoft Forms link
│
├── data/                       # Empirical survey responses
│   ├── raw_responses.csv       # Raw export from Google Forms
│   └── cleaned_data.csv        # Preprocessed data ready for R modeling
│
├── r_scripts/                  # Reproducible R analysis code (Report Appendix)
│   ├── 01_eda_cleaning.R       # Data import, summary statistics & assumption checks
│   └── 02_cca_analysis.R       # Canonical correlation modeling, tests & visualization
│
├── presentation/               # Slide deck for VGU campus presentation (Nov 16)
│   └── cca_presentation.pptx   # Final presentation slides
│
└── report/                     # Final written project report (Nov 25)
    └── cca_project_report.pdf  # Submitted PDF report (2-3 pages per member)
```

---

## 🚀 Immediate Next Action Steps

1. [x] Select Topic: **Canonical Correlation Analysis (CCA)**.
2. [ ] **Moodle Registration (Deadline: Nov 4):** Register team members & lock in topic with Prof. Andersson.
3. [ ] **Draft Survey Questions:** Finalize Set $X$ and Set $Y$ variables and publish Google Form to VGU peers.
4. [ ] **Collect Responses:** Gather at least 50–100 responses across campus.
5. [ ] **Prepare Presentation (Deadline: Nov 16):** Build slides and assign 3–5 min speaking parts.
6. [ ] **Execute R Analysis & Write Report (Deadline: Nov 25):** Process survey data, produce canonical variate plots, and compile the final report.
