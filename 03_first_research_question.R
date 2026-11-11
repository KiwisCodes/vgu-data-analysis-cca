# 03_first_research_question.R - Main CCA + 3 focused research questions
#
# For each analysis this reports only:
#   1. Rc1 (first canonical correlation) and the overall Wilks' Lambda p-value
#   2. The drivers of dimension 1 in each set
#
# How to read the driver tables:
#   Loading = correlation between the variable and its canonical variate.
#             |Loading| >= DRIVER_CUTOFF marks a driver.
#   Weight  = the variable's unique contribution, holding the other variables in its set fixed.
#   Cross   = cross-loading: correlation between the variable and the OTHER set's variate,
#             i.e. how directly this habit relates to the outcome side (or vice versa).
#   Signs are aligned so the strongest outcome (Set Y) loads positively. A habit with a
#   + loading goes with higher values of the + outcomes; a - loading goes with lower values.
#   "shared" = the variable loads highly only because it overlaps with another driver
#              (weight near 0 or opposite sign), so don't interpret it on its own.

data <- read.csv("survey_clean_unstandardized.csv")

DRIVER_CUTOFF <- 0.30

habits      <- c("x_sleep_hours", "x_phone_bed", "x_sitting_hours", "x_workout_hours",
                 "x_friends_hangout", "x_friends_study", "x_ai_reliance")
outcomes    <- c("y_gpa_pct", "y_academic_rank", "y_failed_courses",
                 "y_total_stress", "y_self_esteem")
performance <- c("y_gpa_pct", "y_academic_rank", "y_failed_courses")

analyses <- list(
  "MAIN: All habits -> all outcomes" =
    list(x = habits, y = outcomes),
  "RQ1: Sitting & sleep -> stress & self-esteem" =
    list(x = c("x_sitting_hours", "x_sleep_hours"),
         y = c("y_total_stress", "y_self_esteem")),
  # The weight of x_phone_bed here is its effect at the same sleep duration
  "RQ2: Sleep & bedtime phone -> performance & stress" =
    list(x = c("x_sleep_hours", "x_phone_bed"),
         y = c(performance, "y_total_stress")),
  "RQ3: Exercise & friends -> academic performance" =
    list(x = c("x_workout_hours", "x_friends_hangout", "x_friends_study"),
         y = performance)
)


# ---- CCA on dimension 1: overall test + drivers ------------------------------
run_cca <- function(data, x_vars, y_vars) {
  X <- scale(data[, x_vars])
  Y <- scale(data[, y_vars])
  n <- nrow(X); p <- ncol(X); q <- ncol(Y)

  cca <- cancor(X, Y)

  # Overall test: is any canonical correlation non-zero? (Wilks' Lambda, Bartlett)
  lambda  <- prod(1 - cca$cor^2)
  chisq   <- -((n - 1) - (p + q + 1) / 2) * log(lambda)
  p_value <- pchisq(chisq, df = p * q, lower.tail = FALSE)

  # Dimension 1 canonical variates, signed so the strongest outcome loads positively
  U <- X %*% cca$xcoef[, 1]
  V <- Y %*% cca$ycoef[, 1]
  y_load <- cor(Y, V)[, 1]
  s <- sign(y_load[which.max(abs(y_load))])

  driver_table <- function(M, own_variate, other_variate, coefs) {
    loading <- s * cor(M, own_variate)[, 1]
    weight  <- s * coefs / sd(own_variate)
    cross   <- s * cor(M, other_variate)[, 1]
    role <- ifelse(abs(loading) < DRIVER_CUTOFF, "",
            ifelse(sign(weight) != sign(loading) | abs(weight) < 0.10, "shared", "DRIVER"))
    out <- data.frame(Variable = names(loading), Loading = round(loading, 3),
                      Weight = round(weight, 3), Cross = round(cross, 3), Role = role)
    out[order(-abs(out$Loading)), ]
  }

  list(n = n, Rc1 = cca$cor[1], p = p_value,
       X = driver_table(X, U, V, cca$xcoef[, 1]),
       Y = driver_table(Y, V, U, cca$ycoef[, 1]))
}

list_drivers <- function(tab) {
  d <- tab[tab$Role == "DRIVER", ]
  if (nrow(d) == 0) return("none")
  paste0(sub("^[xy]_", "", d$Variable), " (", sprintf("%+.2f", d$Loading), ")", collapse = ", ")
}


# ---- Run everything (printed and saved to file) ------------------------------
results <- lapply(analyses, function(a) run_cca(data, a$x, a$y))

sink("research_questions_results.txt", split = TRUE)

for (name in names(results)) {
  r <- results[[name]]
  cat("\n==============================================================\n")
  cat(name, "\n")
  cat(sprintf("Rc1 = %.3f   p = %.4f   (N = %d)\n", r$Rc1, r$p, r$n))
  cat("==============================================================\n")
  cat("\nSet X (habits)\n");   print(r$X, row.names = FALSE)
  cat("\nSet Y (outcomes)\n"); print(r$Y, row.names = FALSE)
}

cat("\n==============================================================\n")
cat("SUMMARY (drivers: |loading| >=", DRIVER_CUTOFF, ")\n")
cat("==============================================================\n")
for (name in names(results)) {
  r <- results[[name]]
  cat(sprintf("\n%s\n  Rc1 = %.3f, p = %.4f\n", name, r$Rc1, r$p))
  cat("  Habit drivers:  ", list_drivers(r$X), "\n")
  cat("  Outcome drivers:", list_drivers(r$Y), "\n")
}

sink()
cat("\nSaved 'research_questions_results.txt'.\n")
