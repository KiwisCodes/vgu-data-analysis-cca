# ==============================================================================
# SCRIPT 01: DATA PREPROCESSING WITH SAFEGUARDS & VALIDATION
# Course: Data Analysis in High Dimensions - Prof. Dr. Christina Andersson
# Topic: Canonical Correlation Analysis (CCA)
# ==============================================================================

# ------------------------------------------------------------------------------
# SAFEGUARD 1: Check and Load Required Packages
# ------------------------------------------------------------------------------
required_packages <- c("readxl")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    message(sprintf("[INFO] Package '%s' not found. Installing now...", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org")
  }
}
library(readxl)

# ------------------------------------------------------------------------------
# SAFEGUARD 2: Dynamic File Search & Path Verification
# ------------------------------------------------------------------------------
# Look for the exact filename, or search for any matching Excel file in current dir
target_filename <- "Responses – Student Lifestyle & Academic Performance Survey.xlsx"

find_survey_file <- function(filename) {
  # 1. Check current directory
  if (file.exists(filename)) return(filename)
  
  # 2. Search for any file with 'Student Lifestyle' in its name
  matches <- list.files(pattern = "Student Lifestyle.*\\.xlsx$", full.names = TRUE, ignore.case = TRUE)
  if (length(matches) > 0) return(matches[1])
  
  # 3. Search in parent directory
  matches_parent <- list.files("..", pattern = "Student Lifestyle.*\\.xlsx$", full.names = TRUE, ignore.case = TRUE)
  if (length(matches_parent) > 0) return(matches_parent[1])
  
  return(NULL)
}

survey_path <- find_survey_file(target_filename)
if (is.null(survey_path)) {
  stop(sprintf("\n[ERROR] Survey file '%s' was NOT found in the current directory or parent directories.\nPlease check the file path and try again.", target_filename))
} else {
  message(sprintf("[SUCCESS] Survey file detected at: '%s'", survey_path))
}

# ------------------------------------------------------------------------------
# SAFEGUARD 3: Load Data & Validate Column Structure
# ------------------------------------------------------------------------------
raw_df <- tryCatch({
  as.data.frame(read_excel(survey_path))
}, error = function(e) {
  stop(sprintf("[ERROR] Failed to read Excel file: %s", e$message))
})

message(sprintf("[INFO] Loaded %d rows and %d columns.", nrow(raw_df), ncol(raw_df)))

if (ncol(raw_df) < 21) {
  stop(sprintf("[ERROR] Expected at least 21 survey columns, but found %d columns. File format may have changed.", ncol(raw_df)))
}

# ------------------------------------------------------------------------------
# SAFEGUARD 4: Detect & Filter Outlier / Troll Submissions
# ------------------------------------------------------------------------------
# Flag criteria for impossible/troll submissions:
# 1. Obvious troll major text (e.g. 'ăn tàn phá hoại')
# 2. Sleeping 0 hours or total daily hours (sleep + workout + sit) > 24 hours
is_troll_major <- grepl("ăn tàn phá hoại", raw_df[[2]], ignore.case = TRUE)
is_impossible_sleep <- (!is.na(raw_df[[4]])) & (raw_df[[4]] <= 0)
is_extreme_failed <- (!is.na(raw_df[[16]])) & (raw_df[[16]] > 15)

invalid_mask <- is_troll_major | is_impossible_sleep | is_extreme_failed
num_invalid <- sum(invalid_mask, na.rm = TRUE)

if (num_invalid > 0) {
  message(sprintf("[SAFEGUARD] Identified %d invalid/troll row(s) and excluded them from analysis.", num_invalid))
  df <- raw_df[!invalid_mask, ]
} else {
  df <- raw_df
}

message(sprintf("[SUCCESS] Final sample size for analysis: N = %d valid respondents.", nrow(df)))

# ------------------------------------------------------------------------------
# 5. Preprocess Set X (Predictor Battery: 7 Lifestyle & Tech Variables)
# ------------------------------------------------------------------------------
# X1: Sleep (Hours)
x1_sleep <- as.numeric(df[[4]])
stopifnot(!anyNA(x1_sleep))

# X2: Bedtime Phone Screen Time (Hours)
x2_phone <- as.numeric(df[[5]])
stopifnot(!anyNA(x2_phone))

# X3: Sitting / Sedentary Time (Hours)
x3_sit <- as.numeric(df[[6]])
stopifnot(!anyNA(x3_sit))

# X4: Workout Time (Hours)
x4_workout <- as.numeric(df[[7]])
stopifnot(!anyNA(x4_workout))

# X5: Hangout Friends
x5_hangout <- as.numeric(df[[8]])
stopifnot(!anyNA(x5_hangout))

# X6: Study Friends
x6_study <- as.numeric(df[[9]])
stopifnot(!anyNA(x6_study))

# X7: AI Reliance Ordinal Score (1 to 7)
map_ai_reliance <- function(txt) {
  if (is.na(txt)) return(4) # fallback midpoint
  if (grepl("don’t use AI|Less than 5%", txt, ignore.case = TRUE)) return(1)
  if (grepl("small things", txt, ignore.case = TRUE))             return(2)
  if (grepl("25%", txt, ignore.case = TRUE))                      return(3)
  if (grepl("I do the idea; AI does the work; I check it", txt, fixed = TRUE)) return(4)
  if (grepl("AI and I share the idea", txt, fixed = TRUE))        return(5)
  if (grepl("check the idea and the details|50%", txt, ignore.case = TRUE)) return(6)
  if (grepl("check the idea only", txt, fixed = TRUE))            return(7)
  return(4) # default
}
x7_ai <- sapply(df[[10]], map_ai_reliance)

X_clean <- data.frame(
  Sleep_Hours     = x1_sleep,
  Bedtime_Phone   = x2_phone,
  Sitting_Hours   = x3_sit,
  Workout_Hours   = x4_workout,
  Hangout_Friends = x5_hangout,
  Study_Friends   = x6_study,
  AI_Reliance     = x7_ai
)

# ------------------------------------------------------------------------------
# 6. Preprocess Set Y (Outcome Battery: 5 Academic & Well-Being Variables)
# ------------------------------------------------------------------------------
# Y1: Unified GPA (0 to 100%)
gpa_scale <- df[[11]]
gpa_4     <- as.numeric(df[[12]])
gpa_10    <- as.numeric(df[[13]])
gpa_ger   <- as.numeric(df[[14]])

y1_gpa_pct <- rep(NA, nrow(df))

# 4-point scale (highest = 4.0)
idx_4 <- grepl("4-point", gpa_scale, ignore.case = TRUE)
y1_gpa_pct[idx_4] <- (gpa_4[idx_4] / 4.0) * 100

# 10-point scale (highest = 10)
idx_10 <- grepl("10-point", gpa_scale, ignore.case = TRUE)
y1_gpa_pct[idx_10] <- (gpa_10[idx_10] / 10.0) * 100

# German scale (1.0 = best, 4.0 = pass)
idx_ger <- grepl("German", gpa_scale, ignore.case = TRUE)
y1_gpa_pct[idx_ger] <- (4.0 - gpa_ger[idx_ger]) / (4.0 - 1.0) * 50 + 50

# Safeguard check on GPA conversion
if (anyNA(y1_gpa_pct)) {
  stop("[ERROR] Some GPA values could not be converted! Check GPA columns.")
}
# Clamp between 0 and 100 just in case
y1_gpa_pct <- pmin(pmax(y1_gpa_pct, 0), 100)

# Y2: Academic Rank (Top 10% = 4, Top 30% = 3, Top 50% = 2, Top 70% = 1, Other = 2.5)
rank_map <- c("Top 10%" = 4, "Top 30%" = 3, "Top 50%" = 2, "Top 70%" = 1, "Other" = 2.5)
y2_rank <- unname(rank_map[df[[15]]])
y2_rank[is.na(y2_rank)] <- 2.5 # safe default

# Y3: Failed Courses
y3_failed <- as.numeric(df[[16]])
stopifnot(!anyNA(y3_failed))

# Y4: PSS-4 Total Stress Score (0 to 16)
# Reverse coding items 18 and 19: (4 - score)
stress_scale <- c("Never" = 0, "Almost never" = 1, "Sometimes" = 2, 
                  "Fairly often" = 3, "Very often" = 4)

p1 <- unname(stress_scale[df[[17]]])
p2 <- unname(stress_scale[df[[18]]]) # Positive: confident -> reverse
p3 <- unname(stress_scale[df[[19]]]) # Positive: going your way -> reverse
p4 <- unname(stress_scale[df[[20]]])

# Check for unexpected text
if (anyNA(p1) || anyNA(p2) || anyNA(p3) || anyNA(p4)) {
  stop("[ERROR] Unrecognized stress scale label found! Please verify PSS-4 text options.")
}

y4_stress <- p1 + (4 - p2) + (4 - p3) + p4

# Y5: Single-Item Self-Esteem (1 to 7)
y5_esteem <- as.numeric(df[[21]])
stopifnot(!anyNA(y5_esteem))

Y_clean <- data.frame(
  GPA_Percent    = y1_gpa_pct,
  Academic_Rank  = y2_rank,
  Failed_Courses = y3_failed,
  Total_Stress   = y4_stress,
  Self_Esteem    = y5_esteem
)

# ------------------------------------------------------------------------------
# 7. Merge Cleaned Data & Save Outputs (Using cbind)
# ------------------------------------------------------------------------------
# Clean major text for descriptive demographics
major_clean <- df[[2]]
major_clean[is.na(major_clean)] <- "Not specified"

# cbind = Column Bind: combine metadata, X, and Y horizontally into one table
final_unstandardized <- cbind(
  Semester = as.numeric(df[[3]]),
  Major    = major_clean,
  X_clean,
  Y_clean
)

out_unstd_path <- "survey_clean_unstandardized.csv"
write.csv(final_unstandardized, out_unstd_path, row.names = FALSE)
message(sprintf("[SUCCESS] Saved unstandardized data to: '%s'", out_unstd_path))

# Standardize variables (Z-scores: mean=0, sd=1) for CCA
X_std <- as.data.frame(scale(X_clean))
Y_std <- as.data.frame(scale(Y_clean))

final_standardized <- cbind(X_std, Y_std)
out_std_path <- "survey_clean_standardized.csv"
write.csv(final_standardized, out_std_path, row.names = FALSE)
message(sprintf("[SUCCESS] Saved standardized data (Z-scores) to: '%s'", out_std_path))

# ------------------------------------------------------------------------------
# SAFEGUARD 8: Final Integrity Assertions
# ------------------------------------------------------------------------------
stopifnot(nrow(X_clean) == 107)
stopifnot(nrow(Y_clean) == 107)
stopifnot(!anyNA(X_std))
stopifnot(!anyNA(Y_std))

cat("\n=======================================================\n")
cat("          PREPROCESSING COMPLETED SUCCESSFULLY         \n")
cat(sprintf("  Valid Observations: %d\n", nrow(final_standardized)))
cat(sprintf("  Set X Variables   : %d (%s)\n", ncol(X_clean), paste(names(X_clean), collapse=", ")))
cat(sprintf("  Set Y Variables   : %d (%s)\n", ncol(Y_clean), paste(names(Y_clean), collapse=", ")))
cat("=======================================================\n")
