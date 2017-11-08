## Portal Plant Data

Plant data were collected nearly continuously from 1978-present. Sampling is ongoing and data will be added over time.  

#### Censuses
Quadrat data is collected in the winter and summer each year. However, due to gaps in funding and personnel, not all censuses have been conducted. Information on each census can be found in [Portal_plant_censuse_dates](Portal_plant_censuse_dates.csv).

An indicator of whether or not an individual quadrat was censused in each season can be found in [Portal_plant_censuses](Portal_plant_censuses.csv). This can be used to differentiate between real zeros and missing data in the abundance data.

#### [Data notes](Portal_plant_datanotes.txt)
Several datanotes are used to indicate specific problems in data collection. In most cases, the data are still appropriate for use.

#### Quadrat Abundance Data
[Portal_plant_quadrats](Portal_plant_quadrats.csv) includes data collected by counting all individuals on a 0.5 m x 0.5 m quadrat at each of 16 permanent locations on each plot. `species` and `abundance` are recorded. Starting in 2015, `cover` (visually estimated) and `cf` (used for unknown species) are also recorded for this data.

#### Species
[Portal_plant_species](Portal_plant_species.csv) contains species codes used in [Portal_plant_quadrats](Portal_plant_quadrats.csv) and [Portal_plant_transects_2015_present](Portal_plant_transects_2015_present.csv). The species list also contains a record of taxonomy changes over time (`altgenus` and `altspecies`), often illuminating why the species code doesn't match the current `genus`, `species`. While `genus` and/or `species` may change over time, `speciescode` remains consistent across the duration of the dataset. The `Community` column can be used to group species into broad ecological communities.

#### Transect Shrub Data
[Portal_plant_transects_2015_present](Portal_plant_transects_2015_present.csv) Species, width intersecting the transect (`start` and `stop`), and greatest height are recorded.

Please refer to [Methods.md](../SiteandMethods/Methods.md) for a complete description of how these data were collected.