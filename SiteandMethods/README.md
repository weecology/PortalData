# Portal Overview Metadata

[**Long-term monitoring and experimental manipulation of a Chihuahuan Desert ecosystem near Portal, Arizona (1977 – 2013).**]
(http://onlinelibrary.wiley.com/doi/10.1890/15-2115.1/full)

### Abstract

Desert ecosystems have long served as model systems in the study of ecological concepts (e.g., competition, resource pulses, top-down/bottom-up dynamics). However, the inherent variability of resource availability in deserts, and hence consumer dynamics, can also make them challenging ecosystems to understand. Study of a Chihuahuan desert ecosystem near Portal, AZ began in 1977. At this site, 24 experimental plots were established in 1977 and divided among controls and experimental manipulations. Experimental manipulations over the years include removal of all or some rodent species, all or some ants, seed additions, and various alterations of the annual plant community.

These data have been used in a variety of publications documenting the effects of the experimental manipulations as well as the response of populations and communities to long-term changes in climate and habitat. Sampling is ongoing and additional data will be published as it is collected.

### Site Description:

The site occurs in an upper-elevation Chihuahuan Desert habitat (1330 m), dominated by a mixture of shrubs (e.g. Acacia sp., Prosopis sp., Flourensia cernua) and grasses (e.g. Aristida sp. Bouteloua sp., Muhlenbergia porteri.). Dominance of grasses versus shrubs has shifted over the 30 years of the study, shifting from what was mainly a desertified open grassland to a mixed shrubland (Brown et al 1997). The site itself sits on a bajada at the base of the Chiricahua Mountains and consists of mainly sandy soils.

The entire study area is approximately 20 ha and within this area there are 24 experimental plots [Figure 1](Portal_Figure1.tif). Each plot is 0.25 ha (50m x 50m) and fenced with hardware cloth topped with aluminum flashing. Access to these plots by rodents is regulated by gates cut into fencing. On each plot there are permanent census grids: one for rodents and ants and another for plants. For the rodent/ant grid, 49 permanent trapping stations are marked by rebar stakes forming a 7x7 grid, with 6.25 m between stakes. Every stake on a plot has a unique identifying number denoting the coordinate of that stake on that plot. For example, stake 11 is the first stake on the first row. Rows are numbered 1 through 7 going from the most northern row to the most southern. Columns are numbered 1 through 7 going from the most western column to the most eastern [Figure 1](Portal_Figure1.tif). The plant grid contains fewer rows and columns (4 rows, 4 columns). Numbering of the plant stakes follows similar rules to the rodent/ant grid, except that even numbered rows and columns are skipped (censuses use rows 1, 3, 5, 7 and columns 1, 3, 5, 7). Each plant quadrat is 1 m south of the rodent/ant stake of the corresponding number. Details for how these grids are used for data collection can be found in the metadata for the specific dataset files. 

The study site is located approximately 6.5 km north and 2 km east of the town of Portal, AZ (31°56'20.29"N 109° 4'47.44"W). We have provided GPS coordinates for the rodent stakes, plant quadrats, plot corners, and the weather station ([Coordinates file](Portal_UTMcoords.csv)). These data were collected March 12 – 17, 2011. A few missing coordinates and the coordinates for the newly-rebuilt corner of plot 24 were collected March 28-29, 2017 with a regular (less accurate) handheld GPS. These are flagged in the data.

#### Fence Replacement: 

By 2004, almost 30 years of desert climate had caused the fences around each plot to begin to deteriorate. A local contractor was hired to gradually replace fences on each plot. Generally, fences were taken down and replaced quickly. In a few cases, fences were down when rodent trapping occurred. These events are marked in the rodent database with a note1=10 flag. Records indicate that fence replacement occurred from 3/1/2004-5/8/2005. During fence replacement, the northeast corner of plot 24 was cut off. After this point, rodent stake 17, and plant quadrat 17, were outside the plot fencing and so were no longer used during trapping and censusing. In March of 2016, the corner of Plot 24 was rebuilt, and censusing resumed at those locations.

#### Site history: 

The site is on U.S. Bureau of Land Management property. This area has a long history of cattle grazing and is currently still stocked with cattle.  No grazing has occurred on the 20 ha site since a cattle fence was erected around the study area in 1977 ([Figure 1](Portal_Figure1.tif)).

#### Climate: 

There are two rainy seasons at the site, occurring roughly from Oct-April and July-Sept. The two rainy seasons result in generally two distinct annual plant communities, with a few bi-seasonal annual species.

### Experimental design: 

The study consists of 24 experimental plots, assigned to various ant, rodent, and plant manipulations. At the onset of the study, one rodent species and one ant species each were suspected to potentially have a disproportionate effect on species interactions at the site. Both southwestern desert specialists, these were *Dipodomys spectabilis* (Banner-tailed kangaroo rat) and *Pogonomyrmex rugosus* (Rough Harvester Ant), respectively. In addition to overall rodent and ant plot treatments, a subset of treatments were designed to target these important species specifically. However, these two species were also locally rare and declining over time. (Its rarity motivated an exception to the ant census protocol for Pogonomyrmex rugosus, to count all colonies on a plot, rather than only colonies in the census area. See [Portal Ant Metadata](../Ants/README.md) for more information). Once it became clear that these specialized treatments were no longer necessary, the plots were converted to one of the general ant or rodent treatment types.

#### Treatments: 

As a result of direct changes to the plots, or the termination of experimental manipulations, changes in treatment assignment occurred in 1985, 1987, 2005, 2009 and 2015. These changes are described in [Portal_plot_treatments](Portal_plot_treatments.csv). Unlike the others, Plot 24 was built in 1979. Blank cells denote no changes in treatment from the previous time period. Pogonomyrmex rugosus is an ant species that built very large colonies at the site, but eventually declined until removal treatments were no longer necessary. Dipodomys spectabilis is a large and typically dominant rodent granivore that also declined during the 1980s. (Table modified from Brown 1998). The experimental rodent treatments were switched on all of the short-term plots in 2015. The plots with no entry after the first column are the subset of plots that have maintained a consistent manipulation since 1977. [Portal_plots](Portal_plots.csv) can be used to correctly assign each plot's treatment over time.

#### Rodent treatments:  

Rodents are manipulated using gates in the fencing of each plot. Rodent removals contain no gates and any rodents captured on those plots are removed. All other plots contain 16 gates (4 per plot side); gates consist of holes cut through the hardware cloth of the fencing. Gate size is used to exclude subsets of the rodent community (larger gates allow all rodents access, smaller gates exclude kangaroo rats). Dimensions for gates on kangaroo rat removal plots are 1.9 cm x 1.9 cm, D. spectabilis removals were 2.6 cm x 3.0 cm, and control plots are 3.7 cm x 5.7 cm. In 2005, Dipodomys spectabilis removals were converted to controls – a state these plots had effectively been in with the local extinction of Dipodomys spectabilis in the late 1990s. Species caught on plots from which they are supposed to be excluded are removed from the site and the access point to the plot is located and eliminated. Plots affected by these treatments are listed in [Portal_plot_treatments](Portal_plot_treatments.csv).

#### Plant treatments: 

Since 1988 there have been no direct manipulations of the plant community. Before 1988, annuals were “removed” by applying an herbicide (brand: Roundup), but this removal was not considered successful and was discontinued (Brown 1998). Plots affected by these treatments are listed in [Portal_plot_treatments](Portal_plot_treatments.csv).

#### Seed additions: 

Since 1985 there have been no seed additions to any plot. Before 1985, seed additions were conducted by applying 96 kg of milo (Sorghum vulgare) and/or millet (Panicum miliaceum) seeds to designated plots (Davidson et al 1985). Plots affected by these treatments are listed in [Portal_plot_treatments](Portal_plot_treatments.csv).

#### Ant treatments: 

Ant manipulations were conducted by applying a commercial poison (Mirex [Allied Chemical Corporation] through 1980 and AMDRO [American Cyanamide Company] afterwards) to designated plots (Davidson et al 1985). Plots affected by these treatments are listed in [Portal_plot_treatments](Portal_plot_treatments.csv). After the July 2009 census, ant treatments and ant censuses were discontinued. 

