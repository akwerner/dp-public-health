# create_allocation_df.r
# Author: David Van Riper
# Created: 2020-09-30
# 
# This script creates data frames that will be used in gt() tables created in the RMD.
require(tidyverse)
require(gt)

#### Constants ####
data_path <- "data/"

# files
geog_file <- "geog_level_alloc.csv"
ddp_query_file <- "ddp_query_alloc.csv"
v20200527_file <- "v20200527_query_alloc.csv"

# dp parameters
p_epsilon = 4.0
sensitivity = 2

#### Load data #### 
geog_alloc <- read_csv(paste0(data_path, geog_file))
ddp_alloc <- read_csv(paste0(data_path, ddp_query_file))
v20200527_alloc <- read_csv(paste0(data_path, v20200527_file))

#### Factor the geog_level variable to keep correct order ####
geog_alloc$geog_level <- factor(geog_alloc$geog_level, levels = c("Nation_State", "County_Block"), labels = c("Nation_State", "County_Block"))

#### Generate geog * crosses ####
ddp_tbls <- crossing(geog_alloc, ddp_alloc) 
v20200527_tbls <- crossing(geog_alloc, v20200527_alloc)

#### Generate the scale values #### 
ddp_tbls <- ddp_tbls %>%
  mutate(epsilon_fraction = geog_allocation * allocation * p_epsilon,
         s = sensitivity / epsilon_fraction)

v20200527_tbls <- v20200527_tbls %>%
  mutate(epsilon_fraction = geog_allocation * allocation * p_epsilon,
         s = sensitivity / epsilon_fraction)

#### Generate the standard deviation for each row ####
ddp_tbls <- ddp_tbls %>%
  mutate(sd = sqrt(2 * s^2))

v20200527_tbls <- v20200527_tbls %>%
  mutate(sd = sqrt(2 * s^2))

#### Add a type variable to differentiate after bind_row ####
ddp_tbls <- ddp_tbls %>%
  mutate(vintage = "ddp")

v20200527_tbls <- v20200527_tbls %>%
  mutate(vintage = "v20200527")

#### Bind dfs together #### 
query_allocs <- bind_rows(ddp_tbls, v20200527_tbls)

#### Create wide df on geog var/scale/sd 
query_allocs_wide <- query_allocs %>%
  pivot_wider(id_cols = c(query, vintage), names_from = geog_level, values_from = c(num_categories, allocation, s, sd)) %>%
  select(vintage, query, num_categories = num_categories_Nation_State, allocation = allocation_Nation_State,s_Nation_State, sd_Nation_State, s_County_Block, sd_County_Block, -allocation_County_Block, -num_categories_County_Block)

#### Clean up ####
rm(ddp_tbls)
rm(ddp_alloc)
rm(geog_alloc)
rm(v20200527_alloc)
rm(v20200527_tbls)
rm(query_allocs)


