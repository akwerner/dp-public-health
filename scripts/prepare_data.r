# prepare_data.r 
# Author: David Van Riper
# Date: 2020-09-28
# 
# This script creates three long data frames - SF1, v1 (Oct 2019) and v2 (June 2020) - and adds sex, age, and race codes to each record.

#### Load packages #### 
require(tidyverse)

#### Factor parameters ####
sex_levels <- c(0,1)
sex_labels <- c("M", "F")

race_levels <- c(0,1,2,3,4,5,6,7, 8,9)
race_labels <- c("na", "white_alone", "black_alone", "aian_alone", "asian_alone", "nhopi_alone", "sor_alone", "two_or_more", "hisp", "white_alone_not_hisp")

age_grp_levels <- c(0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17)
age_grp_labels <- c("0-4", "5-9", "10-14", "15-19", "20-24", "25-29", "30-34", "35-39", "40-44", "45-49", "50-54", "55-59", "60-64", "65-69", "70-74", "75-79", "80-84", "85+")

version_levels <- c("sf", "v1", "v2")
version_labels <- c("sf", "v1", "v2")

#### Prepare single recode df #### 
recode <- rbind(sex_age_five_year_recode.csv, sex_age_five_year_whitealone_recode.csv, sex_age_five_year_blackalone_recode.csv, sex_age_five_year_aianalone_recode.csv, sex_age_five_year_asianalone_recode.csv, sex_age_five_year_nhopialone_recode.csv, sex_age_five_year_soralone_recode.csv, sex_age_five_year_twoormore_recode.csv, sex_age_five_year_hisp_recode.csv, sex_age_five_year_whitealone_nothisp_recode.csv)

#### Remove sex_age recodes ####
rm(list=ls(pattern="^sex_"))

#### Create an SF1, v1, and v2 df with just age/sex/race variable ####
sf <- v2 %>%
  select(gisjoin, H76001_sf:H76049_sf, H9A001_sf:H9I049_sf)

v2 <- v2 %>%
  select(gisjoin, H76001_dp:H76049_dp, H9A001_dp:H9I049_dp)

v1a <- v1a %>%
  select(gisjoin, H76001_dp:H76049_dp)

#### Create long dfs for sf, v2, and v1s #### 
# pivot longer, separate var into multiple parts and add a version value
long_sf <- sf %>%
  pivot_longer(H76001_sf:H9I049_sf, names_to = "var", values_to = "n") %>%
  separate(var, into = c("var_code", "version"), sep = "_")

long_v2 <- v2 %>%
  pivot_longer(H76001_dp:H9I049_dp, names_to = "var", values_to = "n") %>%
  separate(var, into = c("var_code", "version"), sep = "_") %>%
  mutate(version = "v2")

long_v1a <- v1a %>%
  pivot_longer(H76001_dp:H76049_dp, names_to = "var", values_to = "n") %>%
  separate(var, into = c("var_code", "version"), sep = "_") %>%
  mutate(version = "v1")

# v1b doesn't require separation because it doesn't have _dp on end of var names 
long_v1b <- v1b %>%
  pivot_longer(H9A001:H9I049, names_to = "var", values_to = "n") %>%
  mutate(version = "v1")

#### Row bind v1a_long and v1b_long into single df #### 
long_v1 <- bind_rows(long_v1a, long_v1b)

#### Row bind all sex by age by race counts into single df ####
df <- bind_rows(long_sf, long_v1)
df <- bind_rows(df, long_v2)

#### Remove unneeded dfs #### 
rm(list = ls(pattern = "^v"))
rm(list = ls(pattern = "^long"))
rm(x)
rm(sf)

#### Join recodes to df #### 
df <- left_join(df, recode, by = c("var_code" = "var")) %>%
  select(-var)

#### Apply factors to age_grp, sex, race, and version #### 
df$sex <- factor(df$sex, levels = sex_levels, labels = sex_labels)
df$race <- factor(df$race, levels = race_levels, labels = race_labels)
df$age_grp <- factor(df$age_grp, levels = age_grp_levels, labels = age_grp_labels)
df$version <- factor(df$version, levels = version_levels, labels = version_labels)

#### Create final sex/age/race df ####
# group by county, version, age_grp, sex, race
# drop NA values before creating the final df 
df_sar <- df %>%
  filter(!is.na(age_grp)) %>%
  group_by(gisjoin, version, age_grp, sex, race) %>%
  summarise(n = sum(n))

