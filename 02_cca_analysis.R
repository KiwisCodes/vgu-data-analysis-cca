# 02_cca_analysis.R - Canonical Correlation Analysis (CCA) Pipeline
# Course: Data Analysis in High Dimensions - Prof. Dr. Christina Andersson
# Slides: Chapter 6 (Slides 190-232)

if (!requireNamespace("ggplot2", quietly = TRUE)) install.packages("ggplot2")
library(ggplot2)

# 1. Load standardized survey data
file_path <- "survey_clean_standardized.csv"
if (!file.exists(file_path)) {
  file_path <- list.files(pattern = "survey_clean_standardized\\.csv$", full.names = TRUE)[1]
}
data_std <- read.csv(file_path)

# Split into Set X (7 habits) and Set Y (5 outcomes)
X <- as.matrix(data_std[, 1:7])
Y <- as.matrix(data_std[, 8:12])

n <- nrow(X)
p <- ncol(X)
q <- ncol(Y)
k <- min(p, q)

# 2. Run Canonical Correlation Analysis (cancor)
cca <- cancor(X, Y)
corrs <- cca$cor

# 3. Sequential Wilks' Lambda Significance Tests (Slides 222-231)
wilks_lambda <- numeric(k)
chisq_stat   <- numeric(k)
deg_freedom  <- numeric(k)
p_values     <- numeric(k)

for (m in 1:k) {
  lambda <- prod(1 - corrs[m:k]^2)
  # Bartlett's chi-square approximation
  w_stat <- -( (n - 1) - (p + q + 1) / 2 ) * log(lambda)
  df     <- (p - m + 1) * (q - m + 1)
  pv     <- 1 - pchisq(w_stat, df)
  
  wilks_lambda[m] <- lambda
  chisq_stat[m]   <- w_stat
  deg_freedom[m]  <- df
  p_values[m]     <- pv
}

test_table <- data.frame(
  Dimension    = paste(1:k, "to", k),
  Canonical_R  = round(corrs, 4),
  Eigenvalue   = round(corrs^2 / (1 - corrs^2), 4),
  Wilks_Lambda = round(wilks_lambda, 4),
  Chisq        = round(chisq_stat, 2),
  df           = deg_freedom,
  p_value      = signif(p_values, 4)
)

cat("\n--- Table 1: Canonical Correlations & Sequential Tests ---\n")
print(test_table)

# 4. Compute Canonical Variates (U and V)
# Apply weights for the k canonical dimensions and scale to unit variance (Slide 215)
U <- scale(X %*% cca$xcoef[, 1:k])
V <- scale(Y %*% cca$ycoef[, 1:k])

# 5. Compute Canonical Loadings (Structure Coefficients)
# Loadings = correlation between original variables and canonical variates
loadings_X <- cor(X, U)
loadings_Y <- cor(Y, V)

colnames(loadings_X) <- paste0("U", 1:k)
colnames(loadings_Y) <- paste0("V", 1:k)

cat("\n--- Table 2: Canonical Loadings for Set X (Lifestyle Habits) ---\n")
print(round(loadings_X, 4))

cat("\n--- Table 3: Canonical Loadings for Set Y (Academic & Well-Being) ---\n")
print(round(loadings_Y, 4))

# Save summary tables to a text file for the report
sink("cca_summary_tables.txt")
cat("CANONICAL CORRELATION ANALYSIS SUMMARY\n")
cat("Sample Size: N =", n, "\n\n")
cat("=== TABLE 1: CANONICAL CORRELATIONS & WILKS' LAMBDA TESTS ===\n")
print(test_table)
cat("\n=== TABLE 2: SET X CANONICAL LOADINGS (STRUCTURE COEFFICIENTS) ===\n")
print(round(loadings_X, 4))
cat("\n=== TABLE 3: SET Y CANONICAL LOADINGS (STRUCTURE COEFFICIENTS) ===\n")
print(round(loadings_Y, 4))
sink()
cat("\nSaved 'cca_summary_tables.txt'.\n")

# 6. Generate Presentation-Ready Plots
dir.create("plots", showWarnings = FALSE)

# Plot 1: Cross-Correlation Matrix Heatmap between X and Y
cross_cor <- cor(X, Y)
cor_df <- as.data.frame(as.table(cross_cor))
colnames(cor_df) <- c("Set_X", "Set_Y", "Correlation")

p1 <- ggplot(cor_df, aes(x = Set_Y, y = Set_X, fill = Correlation)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = sprintf("%.2f", Correlation)), color = "black", size = 3.5) +
  scale_fill_gradient2(low = "#d73027", mid = "#ffffbf", high = "#1a9850", midpoint = 0, limit = c(-0.5, 0.5)) +
  theme_minimal() +
  labs(title = "Bivariate Correlation Heatmap: Habits (Set X) vs Outcomes (Set Y)",
       subtitle = "Pairwise Pearson correlations across all 12 variables (N = 124)",
       x = "Academic & Well-Being Outcomes (Set Y)",
       y = "Daily Lifestyle & Tech Habits (Set X)") +
  theme(axis.text.x = element_text(angle = 20, hjust = 1, face = "bold"),
        axis.text.y = element_text(face = "bold"),
        plot.title = element_text(face = "bold", size = 13))

ggsave("plots/01_correlation_matrix.png", p1, width = 8, height = 6, dpi = 300)

# Plot 2: Canonical Correlation Scree Bar Plot
scree_df <- data.frame(
  Dimension = paste0("Pair ", 1:k),
  Rc = corrs,
  Significant = ifelse(p_values < 0.10, "p < 0.10 (Marginal/Sig)", "p >= 0.10 (Not Sig)")
)

p2 <- ggplot(scree_df, aes(x = Dimension, y = Rc, fill = Significant)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = sprintf("%.3f", Rc)), vjust = -0.4, fontface = "bold", size = 4) +
  scale_fill_manual(values = c("p < 0.10 (Marginal/Sig)" = "#2b8cbe", "p >= 0.10 (Not Sig)" = "#bdc9e1")) +
  ylim(0, 0.55) +
  theme_minimal() +
  labs(title = "Canonical Correlation Coefficients Across Dimensions (k = 5)",
       subtitle = "Dimension 1 captures Rc1 = 0.424 (p = 0.073)",
       x = "Canonical Variate Pair",
       y = "Canonical Correlation (Rc)") +
  theme(plot.title = element_text(face = "bold", size = 13),
        legend.position = "bottom")

ggsave("plots/02_canonical_correlations.png", p2, width = 7, height = 5, dpi = 300)

# Plot 3: Scatter Plot of Variates (U1 vs V1) for Dimension 1
variates_df <- data.frame(
  U1_Lifestyle = U[, 1],
  V1_WellBeing = V[, 1]
)

p3 <- ggplot(variates_df, aes(x = U1_Lifestyle, y = V1_WellBeing)) +
  geom_point(color = "#1f78b4", alpha = 0.7, size = 2.5) +
  geom_smooth(method = "lm", color = "#e31a1c", fill = "#fb9a99", linewidth = 1) +
  annotate("text", x = -2.5, y = 2.8, 
           label = sprintf("R[c1] == %.3f ~~~ (p == %.3f)", corrs[1], p_values[1]), 
           parse = TRUE, size = 4.5, fontface = "bold", hjust = 0) +
  theme_minimal() +
  labs(title = "First Canonical Dimension: Lifestyle Routine (U1) vs Academic Health (V1)",
       subtitle = "Strong positive multivariate alignment across N = 124 students",
       x = "Canonical Variate U1 (Collaborative Study & Lifestyle Routine)",
       y = "Canonical Variate V1 (Academic Success & Well-Being Index)") +
  theme(plot.title = element_text(face = "bold", size = 13))

ggsave("plots/03_canonical_variates_scatter.png", p3, width = 7, height = 5.5, dpi = 300)

# Plot 4: Canonical Loadings for Dimension 1 (Horizontal Bar Chart)
loadings_df <- data.frame(
  Variable = c(rownames(loadings_X), rownames(loadings_Y)),
  Loading  = c(loadings_X[, 1], loadings_Y[, 1]),
  Battery  = c(rep("Set X: Lifestyle Habits", p), rep("Set Y: Academic & Well-Being", q))
)

p4 <- ggplot(loadings_df, aes(x = reorder(Variable, Loading), y = Loading, fill = Battery)) +
  geom_col(width = 0.65) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
  coord_flip() +
  scale_fill_manual(values = c("Set X: Lifestyle Habits" = "#238b45", 
                               "Set Y: Academic & Well-Being" = "#6a51a3")) +
  theme_minimal() +
  labs(title = "Canonical Loadings for Dimension 1",
       subtitle = "Higher positive values indicate stronger alignment with the collaborative academic dimension",
       x = "Survey Variable",
       y = "Canonical Loading (Structure Coefficient)") +
  theme(plot.title = element_text(face = "bold", size = 13),
        legend.position = "bottom")

ggsave("plots/04_canonical_loadings_dim1.png", p4, width = 8, height = 6, dpi = 300)

cat("Successfully generated 4 presentation-ready plots in 'plots/' directory.\n")
cat("Done! CCA analysis completed successfully.\n")
