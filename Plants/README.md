#Portal Plant Monitoring Metadata

[**Long-term monitoring and experimental manipulation of a Chihuahuan Desert plant community near Portal, Arizona (1981 – 2013).**](http://onlinelibrary.wiley.com/doi/10.1890/15-2115.1/full)

###Abstract

The data set includes ongoing detailed annual and perennial plant sampling of an arid ecosystem in near Portal, Arizona. Each year rooted plants are counted within 16 fixed quadrats on each of 24 experimental plots.  The data set should prove useful for studying population dynamics and species interactions. Sampling is ongoing and data will be added over time.  

###Site description: 

Within the 20 ha study area there are 24 experimental plots. Each plot has an area of 0.25 ha and is fenced to regulate rodent access to the plot. Rodent treatments include controls, kangaroo rat removal, and rodent removal. The ant community, which is also predominately granivorous, is also manipulated. Ant treatments include controls and ant removals. 
On each plot there are 16 permanent stations marked by rebar stakes forming a 4x4 grid. Rows are numbered 1,3,5,7 going from the most northern row to the most southern. Columns are numbered 1,3,5,7 going from the most western column to the most eastern. Every quadrat on a plot has a unique identifying number denoting the coordinate of that stake on that plot. For example, quadrat 35 is at the fifth stake on the third row. The numbering of the plant stakes reflects that each plant stake is 1 m south of the rodent/ant stake of the same number (see [Portal Overview Metadata, Figure 1](../SiteandMethods/Portal_Figure1.tif)). Starting in 2005, quadrat 17 was no longer censused in plot 24, due to changes in plot shape putting 17 outside the plot fence. In March of 2016, the corner of Plot 24 was rebuilt and censusing resumed on quadrat 17.

####Description of Winter Communities:  

The first winter annuals typically germinate in response to the first autumn rains in October or November but there tends to be considerable variation among winter species in the timing of germination and initial growth.  Maximum flowering occurs in late spring (late March/early April) and all annual species (except biennials) senesce by May.  

####Description of Summer Communities: 

Typically, germination of summer annuals begins within a few days of the first summer rains in late June or early July. Maximum flowering typically occurs in late August or early September and annual plants senesce by October. 

####Treatments: 

See [Portal Overview Metadata Table 2](../SiteandMethods/Portal_Table2.pptx), for details on treatment assignments for each plot.

###Data Collection: 

####Quadrat Abundance Data

Plant data were collected nearly continuously from 1978-present. Because there are two annual plant communities – one in the winter and one in the summer - there are two plant surveys per year. The surveys occur towards the end of the growing season; occurring in spring for the winter community and fall for the summer community. **Plant censuses were of sufficient quality by 1981 that data has been provided starting in this year. However, there are concerns that not all species were always identified and recorded, especially perennials, in the data from 1981 – 1988.** We are certain that by 1989 all species were being identified and recorded, including all perennials occurring on quadrats. This data is in the [Portal_plant_quadrats](Portal_plant_quadrats.csv) file, where "cover" and "cf" columns were not used. Beginining in the summer of 2015, % cover was recorded by species and included in the abundance table. Unknown species are also assigned a similar species in the "cf" columns where possible. This data is in the [Portal_plant_quadrats](Portal_plant_quadrats.csv) file and uses the "cover" and "cf" columns. It is continually updated with new data. Dates of plant censuses, when known, are listed in [Portal_plant_census_dates](Portal_plant_census_dates.csv). Due to intermittent funding, gaps in data collection exist beginning in 2010. On a quadrat level, the data file [Portal_plant_censuses](Portal_plant_censuses.csv) provides a record of when each quadrat was censused.

Quadrat dimensions are 0.25 m x 0.25 m. Quadrats are placed at locations permanently marked by a rebar stake. Plants rooted within 16 fixed quadrats in each plot are counted each spring (winter annual survey) and fall (summer annual survey). Several adjacent stems are counted separately when the species is an annual, and as one individual when the species is a perennial. **Prior to 1989, perennial species were not systematically included in these counts of abundance.** The [species list](Portal_plant_species.csv) indicates species that are considered perennial at the site.

####Transect Shrub Data
Transect data on shrub cover and abundance resumed in 2015. This data is collected yearly, during the summer plant census. Transects are run diagonally across the plots, from the corner nearest stake 11, and the corner nearest stake 71. Species, width intersecting the transect, and greatest height are recorded. Only species with woody or persistent growth are counted in this census. *Annual and herbaceaous perennial species are not included in this data.* In the first year of collection, 2015, only one location on the transect was recorded fore each individual (start and stop values are the same, and are actually the midpoint at which the shrub intersected the transect).