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

### Health outcomes possibilities 

Finding small area (even county-level) health outcomes data which can be stratified by anything (race, age) is challenging. Florida is the only state for which I can find data stratified by race. Asthma data are typically stratified by age (FL, MA at least). 

#### Florida
The state of Florida has a health outcome tracking dashboard that supports CSV downloads. We can get _low birth weight_ (LBW) and _pre-term birth_ (PTB) counts for counties and census tracts, stratified by:

- Race
  - White, not Hispanic 
  - Black, not Hispanic 
  - Hispanic
  - Other, not Hispanic
- Age
  - Under 20
  - 20 to 29
  - 30 to 39
  - 40 and over
  
We can download counts for all counties in Florida. To download counts by county, you have to go county by county, which is quite time-consuming. We could consider a few counties or ask Florida tracking for a CSV of all counties. 

_Asthma ED visits_

Florida also provides asthma ED visits for 5-year age bins up to 85+ for the same race categories as LBW/PTB. They do suppress small counts, but there seems to be a decent amount of county-level data available. 

Existing denominator data supports _white, not Hispanic_ and _Hispanic_ categories.   

_Childhood blood lead_

- 2012 is first available year with data 
- County counts
- Under age 3 or under age 6
  - need to use single year of age data for this
- No other stratification possible

#### Missouri 

The state of Missouri has a health outcome tracking dashboard that supports CSV downloads. We can get a number of outcomes (blood lead level, AMI, low birth weights) at the county level for 2010. There will be suppression/confidentiality in the county-level counts, especially as we stratify the data, but we can get counts for a decent number of counties. 

#### Massachusetts 

_Asthma ED visits_ 

- MCD 
- age groups (under 5, 5-14, 15-34, 35-64, 65 and over)
- off spine geography by age group
- some suppression for age groups, but that's expected
- successfully downloaded asthma ED visits for towns 

_Childhood blood lead_ 

- data begins in 2012
- Estimated confirmed >= 5 micrograms per dL
- Community by tract (or just community-level counts)
- 0 to 4 years of age 
- small cell counts at census tract level when restricted to single year's worth of data
- it is downloadable as a CSV!

#### Michigan 

_Childhood blood lead_ 

- data begins in 2000
- Estimated confirmed >= 5 micrograms per dL
- county-level data
- 0 to 6 years of age (but I think it's just 0-5 yeras of age)
- it is downloadable as a CSV!

#### Colorado 

_Childhood blood lead_

- data begins in 2008
- single spreadsheet available at https://drive.google.com/file/d/1zOxwxGWqqqRNBiE5ZIrqEvdCRubTv5Kd/view
- I downloaded the file on 2020-09-29 to make sure I had it
- also focused on children under the age of 6 (I think it's just 0-5)

#### Maine 

_Childhood blood lead_

- data is grouped from 2009-2013
- town level counts 
- age 0, 1, or 2 (up to 36 months of age)
- downloaded excel file just to have it

#### New Mexico 

_Childhood blood lead_

- data is grouped from 2009-2013
- county level counts 
- can specify which ages to include






