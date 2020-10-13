# prepare_sex_age_data_mcd.r 
# Author: David Van Riper
# Date: 2020-10-12
# 
# This script creates three long data frames - SF1, v1 (Oct 2019) and v2 (June 2020) - and adds sex and age recodes to each record

#### Load packages #### 
require(tidyverse)

#### Factor parameters ####
sex_levels <- c(0,1)
sex_labels <- c("M", "F")

age_grp_levels <- c(0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,100,200,300,400,500,600,700,800,900,1000,1100,1200,1300,1400,1500,1600,1700,1800,1900,2000)
age_grp_labels <- c("0-4", "5-9", "10-14", "15-19", "20-24", "25-29", "30-34", "35-39", "40-44", "45-49", "50-54", "55-59", "60-64", "65-69", "70-74", "75-79", "80-84", "85+", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19")

version_levels <- c("sf", "v1", "v2")
version_labels <- c("sf", "v1", "v2")

#### Select records for Massachussetts #### 
v2 <- v2 %>%
  filter(state == "25")

v1 <- v1 %>%
  mutate(state = str_sub(gisjoin, 2,3)) %>%
  filter(state == "25")

#### Create a gisjoin - name fc ####
mcd_name <- v1 %>%
  select(gisjoin, name_sf)

# remove city town and Town from name_sf 
mcd_name <- mcd_name %>%
  mutate(name = name_sf) %>%
  mutate(name = str_remove(name, "city"),
         name = str_remove(name, "Town"),
         name = str_remove(name, " town"),
         name = str_trim(name)) 

#### Create pop size categories for MCDs in MA #### 
mcd_pop <- v1 %>%
  select(gisjoin, H7V001_sf) %>%
  mutate(pop_bin = case_when(H7V001_sf < 1000 ~ 1,
                             H7V001_sf >= 1000 & H7V001_sf < 2500 ~ 2,
                             H7V001_sf >= 2500 & H7V001_sf < 5000 ~ 3,
                             H7V001_sf >= 5000 & H7V001_sf < 10000 ~ 4,
                             H7V001_sf >= 10000 & H7V001_sf < 25000 ~ 5,
                             H7V001_sf >= 25000 & H7V001_sf < 50000 ~ 6,
                             H7V001_sf > 50000 ~ 7))

# factor pop_bin 
mcd_pop$pop_bin <- factor(mcd_pop$pop_bin, labels = c("< 1k", "1 - 2.5k", "2.5 - 5k", "5 - 10k", "10 - 25k", "25 - 50k", "> 50k"))
  
#### Create an SF1, v1, and v2 df with just age/sex variables ####
sf <- v2 %>%
  select(gisjoin, H76001_sf:H76049_sf, H78001_sf:H78043_sf)

v2 <- v2 %>%
  select(gisjoin, H76001_dp:H76049_dp, H78001_dp:H78043_dp)

v1 <- v1 %>%
  select(gisjoin, H76001_dp:H76049_dp, H78001_dp:H78043_dp)

#### Create long dfs for sf, v2, and v1s #### 
# pivot longer, separate var into multiple parts and add a version value
long_sf <- sf %>%
  pivot_longer(H76001_sf:H78043_sf, names_to = "var", values_to = "n") %>%
  separate(var, into = c("var_code", "version"), sep = "_")

long_v2 <- v2 %>%
  pivot_longer(H76001_dp:H78043_dp, names_to = "var", values_to = "n") %>%
  separate(var, into = c("var_code", "version"), sep = "_") %>%
  mutate(version = "v2")

long_v1 <- v1 %>%
  pivot_longer(H76001_dp:H78043_dp, names_to = "var", values_to = "n") %>%
  separate(var, into = c("var_code", "version"), sep = "_") %>%
  mutate(version = "v1")

#### Row bind all sex by age by race counts into single df ####
df <- bind_rows(long_sf, long_v1)
df <- bind_rows(df, long_v2)

#### Remove unneeded dfs #### 
rm(v1)
rm(v2)
rm(sf)
rm(list = ls(pattern = "^long"))

#### Join recodes to df #### 
df <- df %>%
  left_join(recode, by = c("var_code" = "var"))

#### Create final sex/age df ####
# group by county, version, age_grp, sex
# drop NA values before creating the final df 
df_sa <- df %>%
  filter(!is.na(age_grp)) %>%
  group_by(gisjoin, version, age_grp, sex) %>%
  summarise(n = sum(n))

#### Split df_sa on age_grp to create a 5-year age bin df and a single year of age df #### 
df_sa_5year <- df_sa %>%
  filter(age_grp < 100)

df_sa_1year <- df_sa %>%
  filter(age_grp > 99)

#### Apply factors to version sex, and age_grp #### 
df_sa_5year$sex <- factor(df_sa_5year$sex, levels = sex_levels, labels = sex_labels)
df_sa_5year$version <- factor(df_sa_5year$version, levels = version_levels, labels = version_labels)
df_sa_5year$age_grp <- factor(df_sa_5year$age_grp, levels = age_grp_levels, labels = age_grp_labels)

df_sa_1year$sex <- factor(df_sa_1year$sex, levels = sex_levels, labels = sex_labels)
df_sa_1year$version <- factor(df_sa_1year$version, levels = version_levels, labels = version_labels)
df_sa_1year$age_grp <- factor(df_sa_1year$age_grp, levels = age_grp_levels, labels = age_grp_labels)

#### Save to rds files #### 
saveRDS(df_sa_1year, "data/df_sa_1year_MA_mcd.rds")
saveRDS(df_sa_5year, "data/df_sa_5year_MA_mcd.rds")



