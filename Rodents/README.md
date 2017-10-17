## Portal Rodent Data

All plots are trapped approximately monthly (1977 - present). Sampling is ongoing and data will be added over time.

#### Rodent adundance data
[Portal_rodent](Portal_rodent.csv) contains the rodent trapping data. Each individual of a target species is PIT tagged and data on species, location caught (plot and stake), sex, reproductive condition, weight, and hindfoot length are recorded.

#### Data Notes 
[Portal_rodent_datanotes](Portal_rodent_datanotes.csv) lists the data flags used in the `Note2` column of [Portal_rodent](Portal_rodent.csv).

#### Species
[Portal_rodent_species](Portal_rodent_species.csv) contains the species codes used in [Portal_rodent](Portal_rodent.csv). Any animal found in a trap is recorded. Non-rodent species are occasionally trapped and so are given species codes. Several columns are also included in the species table to restrict the species list to only rodents, only target species, or only granivores.

#### Trapping
Occasionally, trapping sessions will be missed either partially or completely due to dangerous weather or other extenuating circumstances. [Portal_rodent_trapping](Portal_rodent_trapping.csv) is a complete list of when trapping was done by `year`, `month` and `plot`. This can be used to differentiate real zeros from missing data in [Portal_rodent](Portal_rodent.csv), and to account for differences in trapping effort when summing abundances.

Trapping is conducted as close to the new moon as possible. This can ocasionally lead to more than one census in a month and it means that censuses and months do not line up conveniently. Months that are entirely missed are not noted in the database. We have generated [moon_dates](moon_dates.csv) to provide a time series of new moon occurences, and align the trapping data to them. While `period` is only the census number and does not account for missing censuses, `newmoonnumber` assigns a number to each new moon, regardless if the census happened or not. Then `period` can be used to connect the data from [Portal_rodent](Portal_rodent.csv) to the more consistent `newmoonnumber`.


Also recall that [Portal_plots](../SiteandMethods/Portal_plots.csv) can be used to correctly assign treatment by year and month.

Please refer to [Methods.md](../SiteandMethods/Methods.md) for a complete description of how these data were collected.