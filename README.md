# dp-public-health
Compare disease rates using DP and SF1 denominators

## Data 
This analysis compares the results of three different datasets - 2010 Summary File 1, October 2019 Demonstration Data Product (v1), and the June 2020 PPMF tabulations (v2). The required data are in three different CSV files:

- _wide_dp1_050.csv_: contains the Oct 2019 data for P12. Sex by Age
- _ddp_county_race_sex_age.csv_: contains the Oct 2019 DP for the P12A-I. Sex by Age by (Race) 
- _nhgis_ppdd_20200527.csv_: contains the June 2020 DP and SF1 data for P12. Sex by Age and P12A-I. Sex by Age by (Race)

These three data files should be stored in a directory called "data". 

## Recodes 
I created a set of recode CSVs to assign each variable its sex, age group, and race. Those recodes are in the data/recodes directory and are used in the prepare_data.r script. In the final data frame, there is a race category with a value of "na". These records are counts for sex by age categories, regardless of race.

## Scripts 
You will need to run two scripts to generate the denominators. This section of the README describes what each script does.

### load_data.r
The load_data.r script loads the three data CSVs and the recode CSVs into data frames using the read_csv() function from the tidyverse. 

### prepare_data.r 
The prepare_data.r script does four things:

1. Converts the wide data frames to a single long data frame (df) using pivot_longer
2. Joins the recodes to the long data frame
3. Applies factors to the sex, age_grp, and race variables 
4. Creates a final data frame `df_sar` through a `group_by(sex, age_grp, race, version, gisjoin)` and a `summarise` (which sums the counts for various age categories)

Step 3 is required because the original age categories in the data aren't in 5-year bins. Step 3 creates counts for those 5-year bins through a summarise.

The final data frame `df_sar` has 2,435,076 records of 6 variables.

## Numerator data
When we choose our numerator data, we will probably have to modify its county FIPS codes to match the `gisjoin` value in the df_sar df. The `gisjoin` value is comprised of the following:

- "G" - assures that the value will be a string
- two digit state FIPS code
- "0" - padding for historic states/territories that no longer exist 
- three digit county FIPS code
- "0" - padding for historic counties that no longer exist 

I typically use the following mutate statement to construct a gisjoin:

` mutate(gisjoin = paste0("G", substr(fips, 1, 2), "0", substr(fips, 3, 5), "0"))`

This snippet assumes you have a variable called `fips`, with the first two digits representing the state and the last three digits representing the county. 


