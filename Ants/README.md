# Portal Ant Monitoring Metadata

[**Long-term monitoring and experimental manipulation of a Chihuahuan Desert ant community near Portal, Arizona (1977 ? 2009).**](http://onlinelibrary.wiley.com/doi/10.1890/15-2115.1/full)

### Abstract

The data set covers a 33 year period (1977-2009) of detailed ant sampling of an arid ecosystem near Portal, Arizona. Each year, ant colonies were counted within 49 circular 2-m radius quadrats on each of 24 experimental plots.  In addition, a yearly bait census was conducted using 25 regularly spaced 10 cm diameter crushed bait piles on each plot. The data set should prove useful for studies of population dynamics and species interactions. Sampling was terminated in 2009.

### Site description:

Within the 20 ha study area there are 24 experimental plots. Each plot has an area of 0.25 ha and is fenced to regulate rodent access to the plot. Rodent treatments include controls, kangaroo rat removal, and rodent removal. The ant community, which is also predominately granivorous, is also manipulated. Ant treatments include controls and ant removals. After 1980, poisoning was conducted with AMDRO (American Cyanamide Company) (Davidson et al 1985).

On each plot there are 49 permanent stations marked by rebar stakes forming a 7x7 grid. Rows are numbered 1-7 going from the most northern row to the most southern. Columns are numbered 1-7 going from the most western column to the most eastern. Every stake on a plot has a unique identifying number denoting the coordinate of that stake on that plot. For example, stake 13 is the third stake on the first row (see [Portal Overview Metadata, Fig 1](../SiteandMethods/Portal_Figure1.tif)). Starting in 2005, stakes 15 ? 17 and 27 were no longer censused in plot 24. Changes to plot shape resulted in all or part of the circular quadrats being outside the plot. 

### Treatments: 

See [Portal Overview Metadata Table 2](../SiteandMethods/Portal_plot_treatments.csv), for details on treatment assignments for each plot. [Portal_plots](../SiteandMethods/Portal_plots.csv) can be used to correctly assign treatment by year and month.

### Data Collection: 

Census of the ant community occurred every year over a two week period during July after the summer monsoons have begun. Data collection ended in 2009.

#### [Bait census](Portal_ant_bait.csv): 

On each plot on one morning in July, we set 25 bait piles on each plot.  Bait piles consist of crushed millet placed on the ground in a 10 cm diameter circle.  Bait piles are placed at the base of the permanent rebar stakes.  In rows 1, 3, 5, and 7 we place bait at all odd column stakes (e.g. stake 11, 13, 15, 17).  In rows 2, 4 and 6, we place bait piles at even numbered column stakes (e.g., stake 22, 24, 26).  This creates a checkerboard layout of bait piles across the entire plot. Baits are established at dawn and ants are allowed to recruit to bait piles for 1.5 hours. After 1.5 hours, all bait piles are censused recording all individuals of all species within the 10 cm diameter bait circle.

#### [Colony census](Portal_ant_colony.csv):  

We record the number of colonies and the number of colony entrances for all diurnal species within a 2 m radius circle that is centered 2 m north of each of the 49 permanent stakes. For each colony entrance, we record the species identity and determine whether any additional entrances exist within 0.5 m.  If so we define that as one colony with multiple entrances.

Exceptions to this methodology, indicated with data [flags](Portal_ant_dataflags.csv): 
For all years: For Solenopsis, we simply recorded the presence (1) of any colony entrance within the 2 m radius circle.  
1977-1983: According to Davidson et al (1985), number of colony entrances within the entire 0.25 ha plot were records for the following species: Novomessor, Pheidole desertorum, Pheidole militicida, Pogonomyrmex barbatus, Pogonomyrmex maricopa, Pogonomyrmex rugosus. Nearest census stake was recorded for these species.
1988-2009: For Novomessor and Pogonomyrmex rugosus, we counted the number of all colony entrances within the entire 0.25 ha plot. Records in the database for these species are the number of colony entrances closest to each stake. 
1984-1987: It is currently unclear whether the data from 1984-1987 follows the 1977-1983 protocol for full plot surveys or the 1988-2009 protocol. Given documentation found referring to the ant census during this time, we suspect protocols were in-line with 1988-2009, but cannot say with certainty.
