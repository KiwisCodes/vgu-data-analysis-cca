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
df <- df[df[[4]] > 0 & df[[2]] != "ăn tàn phá hoại", ]

# 3. Build Set X (Lifestyle & Tech habits)
map_ai <- function(x) {
  if (grepl("don’t use AI|Less than 5%", x, ignore.case = TRUE)) return(1)
  if (grepl("small things", x, ignore.case = TRUE))             return(2)
  if (grepl("25%", x, ignore.case = TRUE))                      return(3)
  if (grepl("I do the idea; AI does the work", x, fixed = TRUE)) return(4)
  if (grepl("AI and I share the idea", x, fixed = TRUE))        return(5)
  if (grepl("details|50%", x, ignore.case = TRUE))              return(6)
  if (grepl("idea only", x, fixed = TRUE))                      return(7)
  return(4)
}

X <- data.frame(
  x_sleep_hours     = as.numeric(df[[4]]),
  x_phone_bed       = as.numeric(df[[5]]),
  x_sitting_hours   = as.numeric(df[[6]]),
  x_workout_hours   = as.numeric(df[[7]]),
  x_friends_hangout = as.numeric(df[[8]]),
  x_friends_study   = as.numeric(df[[9]]),
  x_ai_reliance     = sapply(df[[10]], map_ai)
)

# 4. Build Set Y (Academic & Well-being outcomes)
# Convert GPA to 0-100% scale
scale_type <- df[[11]]
gpa_pct <- rep(NA, nrow(df))
gpa_pct[grepl("4-point", scale_type)]  <- (as.numeric(df[[12]][grepl("4-point", scale_type)]) / 4) * 100
gpa_pct[grepl("10-point", scale_type)] <- (as.numeric(df[[13]][grepl("10-point", scale_type)]) / 10) * 100
gpa_pct[grepl("German", scale_type)]   <- (4 - as.numeric(df[[14]][grepl("German", scale_type)])) / 3 * 50 + 50

# Academic rank (1 = Top 70%, 4 = Top 10%)
rank_map <- c("Top 10%" = 4, "Top 30%" = 3, "Top 50%" = 2, "Top 70%" = 1, "Other" = 2.5)
academic_rank <- unname(rank_map[df[[15]]])
academic_rank[is.na(academic_rank)] <- 2.5

# PSS-4 Stress score (items 18 and 19 reverse-coded)
s_map <- c("Never" = 0, "Almost never" = 1, "Sometimes" = 2, "Fairly often" = 3, "Very often" = 4)
total_stress <- unname(s_map[df[[17]]]) + 
                (4 - unname(s_map[df[[18]]])) + 
                (4 - unname(s_map[df[[19]]])) + 
                unname(s_map[df[[20]]])

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
