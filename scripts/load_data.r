# load_data.r 
# Author: David Van Riper
# Date: 2020-09-28
# 
# This script loads in county-level DP and SF1 data for the 2020 APHA conference. This analysis uses two DP datasets - Oct 2019 and May 2020. The 
# other release (Sept 2020) doesn't have race by sex by age data. 

#### Load packages #### 
require(tidyverse)
require(data.table)

#### Constants #### 
data_path <- "data/"
recode_path <- "data/recodes/"

#### Read in files ####
# wide_dp1_050.csv contains the Oct 2019 DP data for P12. Sex by Age  
# ddp_county_race_sex_age.csv contains the Oct 2019 DP for the P12A-I. Sex by Age by (Race) 
# nhgis_ppdd_20200527.csv contains the June 2020 DP and SF1 data for P12. Sex by Age and P12A-I. Sex by Age by (Race)
v1 <- read_csv(paste0(data_path, "wide_dp1_050.csv"))
#v1b <- read_csv(paste0(data_path, "ddp_county_race_sex_age.csv" ))
v2 <- read_csv(paste0(data_path, "nhgis_ppdd_20200527_county.csv"))

#### Read in recodes ####
# Load the sex_age_recode for 5 year age bins and 1 year ages
recode <- read_csv(paste0(recode_path, "sex_age_recode.csv"))

# file_list <- list.files(recode_path)
# 
# for(i in file_list){
#   x <- read_csv(paste0(recode_path, i))
#   
#   assign(i, x)
# }

