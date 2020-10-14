# ma_asthma_mcd_data.r 
# Author: David Van Riper
# Date: 2020-10-12
# 
# This script reads in the Hospitalization data from Massachusetts Department of Health, computes percent diffs between sf and v1/v2, and generates
# box plots and tables.

require(tidyverse)
require(janitor)
require(RColorBrewer)


options(scipen=999)

#### Constants #### 
health_data_path <- "data/health_outcomes/"

#### Read in RDS file for MA mcd #### 
df <- readRDS("data/df_sa_5year_MA_mcd.rds")

#### Read in Asthma ED visit data #### 
ed <- read_csv(paste0(health_data_path, "hospitalization.csv"))

#### Clean field names #### 
ed <- clean_names(ed)

#### Keep required fields ####
# only need the MCD data 
ed <- ed %>%
  select(geo_description, year, age_group, case_count, census_population, crude_rate, age_adjusted_rate, crude_lower_ci, crude_upper_ci, statistical_difference, stability, supression_flag)

# Modify names of Manchester and Townsend 
ed <- ed %>%
  mutate(name = geo_description,
         name = case_when(name == "Manchester" ~ "Manchester-by-the-Sea",
                          name == "Townsend" ~ "send",
                          TRUE ~ name))

#### Assign a gisjoin to each ed record #### 
ed  <- ed %>%
  left_join(mcd_name, by = c("name" = "name"))

#### Modify the df_sa_5year df to match age groups in MA ED data ####
# Under 5
# 5 to 14
# 15 to 34
# 35 to 64
# 65+
df <- df %>%
  mutate(ma_age_grp = case_when(age_grp == "0-4" ~ 1,
                                age_grp == "5-9" | age_grp == "10-14" ~ 2,
                                age_grp == "15-19" | age_grp == "20-24" | age_grp == "25-29" | age_grp == "30-34" ~ 3,
                                age_grp == "35-39" | age_grp == "40-44" | age_grp == "45-49" | age_grp == "50-54" | age_grp == "55-59" | age_grp == "60-64" ~ 4,
                                TRUE ~ 5))

df$ma_age_grp <- factor(df$ma_age_grp, labels = c("Under 5 Years", "5 to 14 Years", "15 to 34 Years", "35 to 64 Years", "65 and over"))

#### Collapse df by gisjoin, version, ma_age_grp to get counts #### 
df_denom <- df %>%
  group_by(gisjoin, version, ma_age_grp) %>%
  summarise(n = sum(n))

#### Join of ED onto df_denom #### 
df_denom_ed <- df_denom %>%
  left_join(ed, by = c("gisjoin" = "gisjoin", "ma_age_grp" = "age_group")) %>%
  filter(!is.na(case_count))

#### Keep required attributes for age adjustment #### 
df_denom_ed <- df_denom_ed %>%
  select(gisjoin, name, version, ma_age_grp, n, case_count)

#### Attempt age adjustments #### 
# loading standard population from nih for 18 age groups
#https://seer.cancer.gov/stdpopulations/
st.pop2000<-
  read.delim("https://seer.cancer.gov/stdpopulations/stdpop.18ages.txt",
             header=F,colClasses = "character")

st.pop2000<-st.pop2000 %>% 
  mutate(st.age.band=as.numeric(str_sub(string=V1, start = 4, end=6)),
         pop=as.numeric(str_sub(string=V1, start = 7, end=14)),
         weight=pop/274633642) %>%
  filter(str_sub(string = V1,start = 1,end = 3)=="204") %>%
  select(st.age.band,pop, weight)

#consolidating age groups to match MA
age_lookup_table<-data.frame(st.age.band=1:18, 
                             ma.age.band = c(
                               1,
                               2,2,
                               3,3,3,3,
                               4,4,4,4,4,4,
                               5,5,5,5,5
                             ))

#adding MA age bands to standard pop dataframe
st.pop2000<-left_join(st.pop2000, age_lookup_table, 
                      by=c("st.age.band"))


#calculating weights for MA age bands
ma.st.pop2000<-st.pop2000 %>% 
  group_by(ma.age.band) %>%
  summarize(weight=sum(weight), pop=sum(pop))

# factor ma.age.band 
ma.st.pop2000$ma.age.band <- factor(ma.st.pop2000$ma.age.band, labels = c("Under 5 Years", "5 to 14 Years", "15 to 34 Years", "35 to 64 Years", "65 and over"))

#### Join the ma.st.pop2000 to df_denom_ed #### 
df_denom_ed <- df_denom_ed %>%
  left_join(ma.st.pop2000, by = c("ma_age_grp" = "ma.age.band"))

#### compute crude prevalence rates for each age group #### 
df_denom_ed <- df_denom_ed %>%
  mutate(crude_rate = case_count / n,
         crute_rate_000s = crude_rate * 1000)

####age adjustment function####
# generate a crude.rate (cases / age group pop for MCD)
# then, multiply that crude.rate by the standard weight for that age group
# do ??????
age.adjust.fun<-function(cases, age.pop, weight, geog.grouping.var, version.grouping.var){
  
  df<-data.frame(cases, age.pop, 
                 crude.rate=cases/age.pop,
                 weight, geog.grouping.var, version.grouping.var)
  
  df$weight.rate <- df$crude.rate*df$weight
  
  
  df<- df %>% group_by(geog.grouping.var, version.grouping.var) %>%
    summarize(age.adjust.rate=sum(weight.rate, na.rm=T),
              crude.rate=sum(cases)/sum(age.pop))
  
  return(df)
}

####Applying function to MA data####
ma_mcd_adjusted_rate <- age.adjust.fun(cases = df_denom_ed$case_count,
                                age.pop = df_denom_ed$n, 
                                weight = df_denom_ed$weight,
                                geog.grouping.var = df_denom_ed$gisjoin,
                                version.grouping.var = df_denom_ed$version)

#### Convert the rates to rate per 10,000 persons ####
ma_mcd_adjusted_rate <- ma_mcd_adjusted_rate %>%
  mutate(age.adjust.rate = age.adjust.rate * 10000,
         crude.rate = crude.rate * 10000)

#### Create a wide df to compute % diffs between sf and v1/v2 #### 
ma_mcd_adjusted_rate_wide <- ma_mcd_adjusted_rate %>%
  pivot_wider(id_cols = geog.grouping.var, names_from = version.grouping.var, values_from = age.adjust.rate) %>%
  mutate(sf_denom_abs_perc_diff_sf_v1 = (abs(sf - v1) / (sf)) * 100,
         sf_denom_abs_perc_diff_sf_v2 = (abs(sf - v2) / (sf)) * 100,
         sf_denom_perc_diff_sf_v1 = ((v1 - sf) / (sf)) * 100,
         sf_denom_perc_diff_sf_v2 = ((v2 - sf) / (sf)) * 100,
         abs_perc_diff_sf_v1 = (abs(sf - v1) / ((sf + v1) / 2)) * 100,
         abs_perc_diff_sf_v2 = (abs(sf - v2) / ((sf + v2) / 2)) * 100,
         perc_diff_sf_v1 = ((v1 - sf) / ((sf + v1) / 2)) * 100,
         perc_diff_sf_v2 = ((v2 - sf) / ((sf + v2) / 2)) * 100)

#### Convert the wide df back to a long df ####
ma_mcd_adjusted_perc <- ma_mcd_adjusted_rate_wide %>%
  pivot_longer(cols = sf:perc_diff_sf_v2, names_to = "var", values_to = "value")

#### Join population bins to ma_mcd_adjusted_perc #### 
ma_mcd_adjusted_perc <- ma_mcd_adjusted_perc %>%
  left_join(mcd_pop, by = c("geog.grouping.var" = "gisjoin"))


#### Summary stats by pop size bin #### 
# absolute percent diffs. 
median_ma_mcd_abs_perc <- ma_mcd_adjusted_perc %>%
  filter(var == "abs_perc_diff_sf_v1" | var == "abs_perc_diff_sf_v2") %>%
  group_by(pop_bin, var) %>%
  summarise(Mean = mean(value, na.rm = TRUE),
            SD = sd(value, na.rm = TRUE),
            P25 = quantile(value, 0.25, na.rm = TRUE),
            P50 = median(value, na.rm = TRUE),
            P75 = quantile(value, 0.75, na.rm = TRUE))

# signed percent diffs.
median_ma_mcd_perc <- ma_mcd_adjusted_perc %>%
  filter(var == "perc_diff_sf_v1" | var == "perc_diff_sf_v2") %>%
  group_by(pop_bin, var) %>%
  summarise(Mean = mean(value, na.rm = TRUE),
            SD = sd(value, na.rm = TRUE),
            P25 = quantile(value, 0.25, na.rm = TRUE),
            P50 = median(value, na.rm = TRUE),
            P75 = quantile(value, 0.75, na.rm = TRUE))

# signed percent diffs. using SF as the denominator
median_ma_mcd_perc_sfdenom <- ma_mcd_adjusted_perc %>%
  filter(var == "sf_denom_perc_diff_sf_v1" | var == "sf_denom_perc_diff_sf_v2") %>%
  group_by(pop_bin, var) %>%
  summarise(Mean = mean(value, na.rm = TRUE),
            SD = sd(value, na.rm = TRUE),
            P25 = quantile(value, 0.25, na.rm = TRUE),
            P50 = median(value, na.rm = TRUE),
            P75 = quantile(value, 0.75, na.rm = TRUE))

#### Box plots by pop size bin #### 

# colors 
oct_color <- brewer.pal(3, "Set1")[1]
july_color <- brewer.pal(3, "Set1")[2]

# Absolute percent difference between sf and v1 / sf and v2
ma_mcd_adjusted_perc %>%
  filter(var == "abs_perc_diff_sf_v1" | var == "abs_perc_diff_sf_v2") %>%
  ggplot(aes(x = pop_bin, y = value, color = var)) + 
    geom_boxplot() + 
    scale_x_discrete(name="Total Population Bins (SF1)") +
    ylab("Absolute Percent Difference (Average denominator)") + 
    scale_color_brewer(palette = "Set1") + 
    labs(caption = "Source: Van Riper et al. 2020; US Census Bureau 2019; Massachusetts Department of Health 2020") +
    ggtitle(paste("2010 SF1 vs. Diff. Private: Absolute Percent Difference in Age-Adjusted Asthma ED Visits (MA towns)")) + 
    annotate("text", x = 0.85, y = 53, label = "Oct. 2019", color = oct_color, size = 4) +
    annotate("text", x = 1.15, y = 40.5, label = "July 2020", color = july_color, size = 4) +
    theme_bw() +
    theme(axis.title = element_text(size = 16),
          axis.text = element_text(size = 12),
          plot.title = element_text(size = 20),
          legend.position = "none",
          panel.border = element_blank())

ggsave(paste("figures/ma_towns_asthma_ed_abs_perc_diff", ".png", sep=""), width=10, height=5.625, dpi=150)

# Percent difference (positive and negative) between sf and v1 / sf and v2
ma_mcd_adjusted_perc %>%
  filter(var == "perc_diff_sf_v1" | var == "perc_diff_sf_v2") %>%
  ggplot(aes(x = pop_bin, y = value, color = var)) + 
  geom_boxplot() + 
  scale_x_discrete(name="Total Population Bins (SF1)") +
  ylab("Percent Difference (Average denominator)") + 
  scale_color_brewer(palette = "Set1") + 
  labs(caption = "Source: Van Riper et al. 2020; US Census Bureau 2019; Massachusetts Department of Health 2020") +
  ggtitle(paste("2010 SF1 vs. Diff. Private: Percent Difference in Age-Adjusted Asthma ED Visits (MA towns)")) + 
  annotate("text", x = 0.85, y = 55, label = "Oct. 2019", color = oct_color, size = 4) +
  annotate("text", x = 1.15, y = 37, label = "July 2020", color = july_color, size = 4) +
  theme_bw() +
  theme(axis.title = element_text(size = 16),
        axis.text = element_text(size = 12),
        plot.title = element_text(size = 20),
        legend.position = "none",
        panel.border = element_blank())

ggsave(paste("figures/ma_towns_asthma_ed_perc_diff", ".png", sep=""), width=10, height=5.625, dpi=150)

#### Box plots with SF as denominator for percent difference #### 

# Absolute percent difference between sf and v1 / sf and v2
ma_mcd_adjusted_perc %>%
  filter(var == "sf_denom_abs_perc_diff_sf_v1" | var == "sf_denom_abs_perc_diff_sf_v2") %>%
  ggplot(aes(x = pop_bin, y = value, color = var)) + 
  geom_boxplot() + 
  scale_x_discrete(name="Total Population Bins (SF1)") +
  ylab("Absolute Percent Difference (SF denominator)") + 
  scale_color_brewer(palette = "Set1") + 
  labs(caption = "Source: Van Riper et al. 2020; US Census Bureau 2019; Massachusetts Department of Health 2020") +
  ggtitle(paste("2010 SF1 vs. Diff. Private: Absolute Percent Difference in Age-Adjusted Asthma ED Visits (MA towns)")) + 
  annotate("text", x = 0.85, y = 53, label = "Oct. 2019", color = oct_color, size = 4) +
  annotate("text", x = 1.15, y = 40.5, label = "July 2020", color = july_color, size = 4) +
  theme_bw() +
  theme(axis.title = element_text(size = 16),
        axis.text = element_text(size = 12),
        plot.title = element_text(size = 20),
        legend.position = "none",
        panel.border = element_blank())

ggsave(paste("figures/sf_denom_ma_towns_asthma_ed_abs_perc_diff", ".png", sep=""), width=10, height=5.625, dpi=150)

# Percent difference (positive and negative) between sf and v1 / sf and v2
ma_mcd_adjusted_perc %>%
  filter(var == "sf_denom_perc_diff_sf_v1" | var == "sf_denom_perc_diff_sf_v2") %>%
  ggplot(aes(x = pop_bin, y = value, color = var)) + 
  geom_boxplot() + 
  scale_x_discrete(name="Total Population Bins (SF1)") +
  ylab("Percent Difference (SF denominator)") + 
  scale_color_brewer(palette = "Set1") + 
  labs(caption = "Source: Van Riper et al. 2020; US Census Bureau 2019; Massachusetts Department of Health 2020") +
  ggtitle(paste("2010 SF1 vs. Diff. Private: Percent Difference in Age-Adjusted Asthma ED Visits (MA towns)")) + 
  annotate("text", x = 0.85, y = 55, label = "Oct. 2019", color = oct_color, size = 4) +
  annotate("text", x = 1.15, y = 37, label = "July 2020", color = july_color, size = 4) +
  theme_bw() +
  theme(axis.title = element_text(size = 16),
        axis.text = element_text(size = 12),
        plot.title = element_text(size = 20),
        legend.position = "none",
        panel.border = element_blank())

ggsave(paste("figures/sf_denom_ma_towns_asthma_ed_perc_diff", ".png", sep=""), width=10, height=5.625, dpi=150)

