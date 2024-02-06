# Covid-Story
### Story link: [The (In)Alienable Rights of Men](https://shivangibishnoi.github.io/covid/index.html)

#### Methodology:
I perform non-parametric regression analysis to find out how daily covid deaths in 2020 and 2021 related to democracy scores. I also investigate the reasons for the observed relationship by breaking up the democracy score into its individual components.

#### Data:
a. ```df_full_eiu.csv``` has the original date from [WZB] (https://wzbipi.github.io/corona/)
b. ```eiu_dem_index.xlsx``` contains the individual components and overall democracy
scores from the EIU’s 2019 democracy report (Note: this was used instead of the
latest report to limit reverse causality concerns since covid-19 itself may have
affected democracy scores)

#### STATA Code:
```stata_code.do``` contains the code that was used to produce the results in
the charts seen in the story. (Note: the code does not automatically produce the charts in the story
but can be used to verify the results)


The stata code has been divided into 2 sections: the section “Main Results” was used to
get the results that were plotted in the three graphs. The rest of the code is for
robustness checks. Estimations for “Chart 1” and “Charts 2 & 3” are marked as such in
the code

 
