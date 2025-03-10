# 259 Homework - exploratory data analysis + integrating skills
# For full credit, answer at least 8/10 questions
# List students working with below:

library(tidyverse)
library(lubridate)
library(DataExplorer)

#> These data are drawn from the fivethirtyeight article:
#> http://fivethirtyeight.com/features/what-12-months-of-record-setting-temperatures-looks-like-across-the-u-s/
#> The directory us-weather-history contains a data file for each of 10 cities, labelled by their station name
#> Each data file contains:
#> `date` | The date of the weather record, formatted YYYY-M-D
#> `actual_mean_temp` | The measured average temperature for that day
#> `actual_min_temp` | The measured minimum temperature for that day
#> `actual_max_temp` | The measured maximum temperature for that day
#> `average_min_temp` | The average minimum temperature on that day since 1880
#> `average_max_temp` | The average maximum temperature on that day since 1880
#> `record_min_temp` | The lowest ever temperature on that day since 1880
#> `record_max_temp` | The highest ever temperature on that day since 1880
#> `record_min_temp_year` | The year that the lowest ever temperature occurred
#> `record_max_temp_year` | The year that the highest ever temperature occurred
#> `actual_precipitation` | The measured amount of rain or snow for that day
#> `average_precipitation` | The average amount of rain or snow on that day since 1880
#> `record_precipitation` | The highest amount of rain or snow on that day since 1880

stations <- c("KCLT", "KCQT", "KHOU", "KIND", "KJAX", "KMDW", "KNYC", "KPHL", "KPHX", "KSEA")
cities <- c("Charlotte", "Los Angeles", "Houston", "Indianapolis", "Jacksonville", 
            "Chicago", "New York City", "Philadelphia", "Phoenix", "Seattle")

# QUESTION 1
#> The data files are in the directory 'us-weather-history'
#> Write a function that takes each station abbreviation and reads
#> the data file and adds the station name in a column
#> Make sure the date column is a date
#> The function should return a tibble
#> Call the function "read_weather" 
#> Check by reading/glimpsing a single station's file

read_weather <- function(station_abbr) {
  file_path <- file.path("us-weather-history", paste0(station_abbr, ".csv"))
  
  # read the CSV
  df <- read_csv(file_path, show_col_types = FALSE) %>%
    mutate(station = station_abbr,
           date = as_date(date)) 
  
  return(df)
}

# test on a single station and glimpse
test_station <- read_weather("KCLT")
glimpse(test_station)

# QUESTION 2
#> Use map() and your new function to read in all 10 stations
#> Note that because map_dfr() has been superseded, and map() does not automatically bind rows, you will need to do so in the code.
#> Save the resulting dataset to "ds"
# map() returns a list of tibbles
l <- map(stations, read_weather)

# bind rows manually (since map_dfr has been superseded)
ds <- bind_rows(l)

glimpse(ds)

# QUESTION 3
#> Make a factor called "city" based on the station variable
#> (station should be the level and city should be the label)
#> Use fct_count to check that there are 365 days of data for each city 
ds <- ds %>%
  mutate(city = factor(station, 
                       levels = stations, 
                       labels = cities))

# check counts by city
fct_count(ds$city)

# QUESTION 4
#> Since we're scientists, let's convert all the temperatures to C
#> Write a function to convert F to C, and then use mutate across to 
#> convert all of the temperatures, rounded to a tenth of a degree
f_to_c <- function(f) {
  (f - 32) * 5/9
}

ds <- ds %>%
  mutate(across(
    .cols = ends_with("temp"),
    .fns  = ~ round(f_to_c(.x), 1)
  ))

glimpse(ds)


### CHECK YOUR WORK
#> At this point, your data should look like the "compiled_data.csv" file
#> in data-clean. If it isn't, read in that file to use for the remaining
#> questions so that you have the right data to work with.

# QUESTION 5
#> Write a function that counts the number of extreme temperature days,
#> where the actual min or max was equal to the (i.e., set the) record min/max
#> A piped function starting with '.' is a good strategy here.
#> Group the dataset by city to see how many extreme days each city experienced,
#> and sort in descending order to show which city had the most:
#> (Seattle, 20, Charlotte 12, Phoenix 12, etc...)
#> Don't save this summary over the original dataset!

count_extreme_days <- . %>%
  summarize(
    extreme_count = sum(actual_min_temp == record_min_temp |
                          actual_max_temp == record_max_temp, 
                        na.rm = TRUE)
  )

ds %>% 
  group_by(city) %>%
  count_extreme_days %>%
  arrange(desc(extreme_count))

# QUESTION 6
#> Pull out the month from the date and make "month" a factor
#> Split the tibble by month into a list of tibbles 
ds <- ds %>%
  mutate(month = factor(month(date), levels = 1:12))

ds_list_by_month <- split(ds, ds$month)

# QUESTION 7
#> For each month, determine the correlation between the actual_precipitation
#> and the average_precipitation (across all cities), and between the actual and average mins/maxes
#> Use a for loop, and print the month along with the resulting correlation
#> Look at the documentation for the ?cor function if you've never used it before
for (m in levels(ds$month)) {
  df_m <- ds_list_by_month[[m]]
  
  cor_precip <- cor(df_m$actual_precipitation, df_m$average_precipitation)
  cor_min    <- cor(df_m$actual_min_temp, df_m$average_min_temp)
  cor_max    <- cor(df_m$actual_max_temp, df_m$average_max_temp)

  cat(
    "month:", m, 
    ":cor(actual vs avg precip):", round(cor_precip, 3), 
    ":cor(min):", round(cor_min, 3), 
    ":cor(max):", round(cor_max, 3), "\n"
  )
}




# QUESTION 8
#> Use the Data Explorer package to plot boxplots of all of the numeric variables in the dataset
#> grouped by city, then do the same thing grouped by month. 
#> Finally, use plot_correlation to investigate correlations between the continuous variables only
#> Check the documentation for plot_correlation for an easy way to do this

# Boxplots by city
plot_boxplot(ds, by = "city")

# Boxplots by month
plot_boxplot(ds, by = "month")

# Correlation plot (continuous variables only)
plot_correlation(ds, type = "continuous")



# QUESTION 9
#> Create a scatterplot of actual_mean_temp (y axis) by date (x axis)
#> Use facet_wrap to make a separate plot for each city (3 columns)
#> Make the points different colors according to month




# QUESTION 10
#> Write a function that takes the dataset and the abbreviate month as arguments
#> and creates a scatter and line plot of actual temperature (y axis) by date (x axis)
#> Note, just add geom_line() to your ggplot call to get the lines
#> use the ggtitle() function to add the month as a title
#> The function should save the plot as "eda/month_name.png"
#> The eda folder has an example of what each plot should look like
#> Call the function in a map or loop to generate graphs for each month


