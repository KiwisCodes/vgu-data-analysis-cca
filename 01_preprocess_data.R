# 01_preprocess_data.R - Clean survey data for CCA

if (!requireNamespace("readxl", quietly = TRUE)) install.packages("readxl")
library(readxl)

# 1. Load survey file
file_path <- "Responses – Student Lifestyle & Academic Performance Survey.xlsx"
if (!file.exists(file_path)) {
  file_path <- list.files(pattern = "Student Lifestyle.*\\.xlsx$", full.names = TRUE)[1]
}
df <- as.data.frame(read_excel(file_path))

# 2. Filter out invalid/troll responses
df <- df[df[[4]] > 0 & (is.na(df[[2]]) | df[[2]] != "ăn tàn phá hoại"), ]

# 3. Build Set X (Lifestyle & Tech habits)
# Exact mapping dictionary for AI options (1 = Minimal to 7 = Max AI autonomy)
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

X <- data.frame(
  x_sleep_hours     = as.numeric(df[[4]]),
  x_phone_bed       = as.numeric(df[[5]]),
  x_sitting_hours   = as.numeric(df[[6]]),
  x_workout_hours   = as.numeric(df[[7]]),
  x_friends_hangout = as.numeric(df[[8]]),
  x_friends_study   = as.numeric(df[[9]]),
  x_ai_reliance     = unname(ai_reliance_map[df[[10]]])
)

# 4. Build Set Y (Academic & Well-being outcomes)
# Exact mapping for GPA scale to 0-100%
scale_type <- df[[11]]
gpa_pct <- rep(NA, nrow(df))
gpa_pct[scale_type == "4-point scale (highest = 4.0)"]         <- (as.numeric(df[[12]][scale_type == "4-point scale (highest = 4.0)"]) / 4) * 100
gpa_pct[scale_type == "10-point scale (highest = 10)"]        <- (as.numeric(df[[13]][scale_type == "10-point scale (highest = 10)"]) / 10) * 100
gpa_pct[scale_type == "German scale (1.0 = best, 4.0 = pass)"] <- (4 - as.numeric(df[[14]][scale_type == "German scale (1.0 = best, 4.0 = pass)"])) / 3 * 50 + 50

# Exact mapping for academic rank (1 = Top 70%, 4 = Top 10%)
rank_map <- c("Top 10%" = 4, "Top 30%" = 3, "Top 50%" = 2, "Top 70%" = 1, "Other" = 2.5)
academic_rank <- unname(rank_map[df[[15]]])

# Exact mapping for PSS-4 stress score (items 18 and 19 reverse-coded)
stress_map <- c("Never" = 0, "Almost never" = 1, "Sometimes" = 2, "Fairly often" = 3, "Very often" = 4)
total_stress <- unname(stress_map[df[[17]]]) + 
                (4 - unname(stress_map[df[[18]]])) + 
                (4 - unname(stress_map[df[[19]]])) + 
                unname(stress_map[df[[20]]])

Y <- data.frame(
  y_gpa_pct        = gpa_pct,
  y_academic_rank  = academic_rank,
  y_failed_courses = as.numeric(df[[16]]),
  y_total_stress   = total_stress,
  y_self_esteem    = as.numeric(df[[21]])
)

# 5. Save unstandardized data (for plots & summary tables)
meta <- data.frame(semester = as.numeric(df[[3]]), major = df[[2]])
write.csv(cbind(meta, X, Y), "survey_clean_unstandardized.csv", row.names = FALSE)

# 6. Save standardized data (z-scores for CCA)
write.csv(cbind(as.data.frame(scale(X)), as.data.frame(scale(Y))), 
          "survey_clean_standardized.csv", row.names = FALSE)

cat("Done! Processed", nrow(X), "valid rows (7 X variables, 5 Y variables).\n")
