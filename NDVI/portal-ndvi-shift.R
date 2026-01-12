library(dplyr)
library(ggplot2)
library(lubridate)
library(portalr)
library(purrr)
library(readr)
library(stringr)

find_sensor_matches <- function(ndvi_data, max_days = 10) {
  ndvi_data$date <- as.Date(ndvi_data$date)
  sensors <- c("Landsat5", "Landsat7", "Landsat8", "Landsat9")
  results_list <- list()

  for (sensor_i in 1:(length(sensors) - 1)) {
    sensor1_data <- ndvi_data |> filter(sensor == sensors[sensor_i])
    sensor2_data <- ndvi_data |> filter(sensor == sensors[sensor_i + 1])
    for (i in 1:nrow(sensor1_data)) {
      current_date <- sensor1_data$date[i]
      current_ndvi <- sensor1_data$ndvi[i]
      current_pixel_count <- sensor1_data$pixel_count[i]
      date_diffs <- abs(as.numeric(sensor2_data$date - current_date))
      min_diff_idx <- which.min(date_diffs)
      min_diff_days <- date_diffs[min_diff_idx]
      if (min_diff_days <= max_days) {
        match_row <- sensor2_data[min_diff_idx, ]
        result_row <- tibble(
          sensor1 = sensors[sensor_i],
          ndvi1 = current_ndvi,
          date1 = current_date,
          pixel_count1 = current_pixel_count,
          sensor2 = sensors[sensor_i + 1],
          ndvi2 = match_row$ndvi,
          date2 = match_row$date,
          pixel_count2 = match_row$pixel_count,
          days_diff = min_diff_days
        )
        results_list <- append(results_list, list(result_row))
      }
    }
  }
  results <- bind_rows(results_list)
  return(results)
}

ndvi <- load_datafile("NDVI/ndvi.csv") |>
  as_tibble()

sensor_matches <- find_sensor_matches(ndvi, max_days = 10)

ndvi_pairs <- sensor_matches |>
  filter(
    days_diff <= 10,
    ndvi1 > 0,
    ndvi2 > 0,
    pixel_count1 > 3562 / 2,
    pixel_count2 > 3562 / 2,
  )

date_ranges <- ndvi |>
  filter(str_detect(sensor, "Landsat")) |>
  group_by(sensor) |>
  summarise(
    min_date = min(date, na.rm = TRUE),
    max_date = max(date, na.rm = TRUE),
    .groups = "drop"
  )

print(date_ranges)

ggplot(ndvi_pairs, aes(x = ndvi1, y = ndvi2)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0) +
  facet_wrap(vars(sensor1, sensor2), scales = "free")

ggsave("ndvi-sensor-comparion-one-to-one.png")

ggplot(ndvi_pairs, (aes(x = ndvi1 - ndvi2))) +
  geom_histogram() +
  geom_vline(xintercept = 0) +
  xlab("Sensor Difference (Current - Previous)") +
  facet_wrap(vars(sensor2), ncol = 1)

ggsave("ndvi-sensor-comparion-histograms.png")

instrument_diffs <- ndvi_pairs |>
  group_by(sensor2) |>
  summarize(correction_to_prev_sensor = mean(ndvi1 - ndvi2))

print(instrument_diffs)
