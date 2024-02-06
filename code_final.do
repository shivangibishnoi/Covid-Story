
cd "/Users/sb7929/Dropbox/My Mac (ADUAEI12711LPMX)/Desktop/Economist Article/Research/Results/2903"

**************************************************
***** Preparing Data and Creating Variables ******
**************************************************

import delimited using "/Users/sb7929/Dropbox/My Mac (ADUAEI12711LPMX)/Desktop/Economist Article/Research/Data/df_full_eiu.csv", clear

* replacing "NA" in all string variables with blanks *

ds, has(type string) 
local varlist `r(varlist)'

foreach v in `varlist'{
	replace `v'= "" if `v' == "NA"
}

* converting date to STATA date format *

generate eventdate = date(date, "DMY")

* destring all numeric variables of interest *

local all vdem_libdem gdp_pc share_older healthcare_qual health_exp_pc resp_disease_prev trust_gov trust_people eiu_dem_score detect_index population_2019 excess_deaths_weekly pop_density polity
 
 destring `all', replace
 
 * creating variable for cumulative cases *
 
 sort country eventdate 
 gen cum_cases = cases[1]
 replace cum_cases = cases[_n] + cum_cases[_n-1] if _n>1
 
 * scaling up deaths and cases by 1 before transforming into logs *
 
 
 gen deaths_1 = deaths + 1
 gen cases_1 = cases + 1
 replace cum_cases = cum_cases +1
 
 * creating logs of variables *
  
 gen lpop = ln(population_2019)
 gen lgdp_pc = ln(gdp_pc)
 
 gen ldeaths = ln(deaths_1)
 gen lcases = ln(cases_1)
 gen lexcees_deaths_weekly = ln(excess_deaths_weekly)
 gen lcum_cases = ln(cum_cases)
 
 gen deaths_pm = deaths_1/(population_2019/1000000)
 gen ldeaths_pm = ln(deaths_pm)
 
 gen cases_pm = cases_1/(population_2019/1000000)
 gen lcases_pm = ln(cases_pm)
 
 gen excess_deaths_weekly_pm = excess_deaths_weekly/(population_2019/1000000)
 gen lexcess_deaths_weekly_pm = ln(excess_deaths_weekly_pm)
 
 * creating dummies for region, categories of government and countries *
 
encode region, gen(regioncode)
encode eiu_class, gen(dem_class)
encode country, gen(country_code)

drop if lpop == .
drop if date == "30/12/2020"

* labelling variables *

label var vdem_libdem "V-Dem Democracy Score"
label var gdp_pc "GDP per-capita"
label var share_older "Share of population 65 and over"
label var health_exp_pc "Health Expenditure per-capita"
label var resp_disease_prev "Respiratory Disease Prevalence"
label var eiu_dem_score "EIU's Democracy Score"
label var eiu_dem_c1 "EIU- electoral process and pluralism"
label var eiu_dem_c2 "EIU- functioning of government"
label var eiu_dem_c3 "EIU- political participation"
label var eiu_dem_c4 "EIU- democratic political culture"
label var eiu_dem_c5 "EIU- civil liberties"


save "/Users/sb7929/Dropbox/My Mac (ADUAEI12711LPMX)/Desktop/Economist Article/Research/Data/df_full_eiu.dta", replace

*************************************
***** Country-level Database ********
*************************************

sort country

drop if eiu_dem_score == .

keep country country_code gdp_pc share_older healthcare_qual health_exp_pc resp_disease_prev trust_gov trust_people eiu_dem_score detect_index population_2019 lpop pop_density polity vdem_libdem eiu_dem_c1 eiu_dem_c2 ///
eiu_dem_c3 eiu_dem_c4 eiu_dem_c5 dem_class 

duplicates drop

save "/Users/sb7929/Dropbox/My Mac (ADUAEI12711LPMX)/Desktop/Economist Article/Research/Data/country_data.dta", replace


graph bar eiu_dem_c4 eiu_dem_c5, over(dem_class, sort(1) descending) title("Mean Scores by Political Regime") legend( label(1 "Democratic Political Culture") label(2 "Civil Liberties")) /// 
note("Source: The Economist Intelligence Unit")


********************************************
********** MAIN RESULTS ********************
********************************************


//////////////////////
* Linear Regression *
//////////////////////




use "/Users/sb7929/Dropbox/My Mac (ADUAEI12711LPMX)/Desktop/Economist Article/Research/Data/df_full_eiu.dta", clear


local x_d share_older health_exp_pc resp_disease_prev i.eventdate i.regioncode detect_index infection lgdp_pc lpop pop_density


foreach x in vdem_libdem eiu_dem_score i.dem_class  {
	eststo clear
	_eststo: reg ldeaths `x'  `x_d'
	outreg2  using baseline_0, keep(vdem_libdem eiu_dem_score i.dem_class share_older healthcare_qual health_exp_pc resp_disease_prev detect_index infection lgdp_pc lpop pop_density) excel
	_eststo: reg ldeaths_pm `x'  `x_d'
	outreg2  using baseline_0, keep(vdem_libdem eiu_dem_score i.dem_class share_older healthcare_qual health_exp_pc resp_disease_prev detect_index infection lgdp_pc lpop pop_density) excel
}

* clustering SE by country *


local x_d share_older health_exp_pc resp_disease_prev i.eventdate i.regioncode detect_index infection lgdp_pc lpop pop_density

foreach x in vdem_libdem eiu_dem_score i.dem_class  {
	eststo clear
	_eststo: reg ldeaths `x'  `x_d', vce(cluster country_code)"

* effect of individual components of EIU's democracy scores *

reg ldeaths eiu_dem_c1 eiu_dem_c2 eiu_dem_c3 eiu_dem_c4 eiu_dem_c5 share_older health_exp_pc resp_disease_prev i.eventdate i.regioncode detect_index infection lgdp_pc lpop pop_density, vce(cluster country_code)

* removing statistically insignificant components *

* CHARTS 2 & 3 *

reg ldeaths eiu_dem_c1 eiu_dem_c4 eiu_dem_c5 share_older health_exp_pc resp_disease_prev i.eventdate i.regioncode detect_index infection lgdp_pc lpop pop_density, vce(cluster country_code)

margins, at(eiu_dem_c4=(1(0.5)10)) post 
estimates store predictions_c4
outreg2 using margins_comp, excel replace


reg ldeaths eiu_dem_c1 eiu_dem_c4 eiu_dem_c5 share_older health_exp_pc resp_disease_prev i.eventdate i.regioncode detect_index infection lgdp_pc lpop pop_density, vce(cluster country_code)

margins, at(eiu_dem_c5=(1(0.5)10)) post 
estimates store predictions_c5
outreg2 using margins_comp, excel  

//////////////////////////////
* Non-Parametric Regression *
/////////////////////////////

*** Nadaraya Watson Kernel Estimation ***

// EIU Democracy Index //

* CHART 1 *

set scheme s1color

npregress kernel ldeaths eiu_dem_score share_older health_exp_pc resp_disease_prev i.eventdate i.regioncode detect_index infection lgdp_pc lpop pop_density

margins, at(eiu_dem_score=(1(0.5)10)) vce(bootstrap, reps(100) seed(123) nodrop)

marginsplot 

* Robustness check with V-Dem score *

// V-DEM Liberal Democracy Score //

npregress kernel ldeaths vdem_libdem share_older health_exp_pc resp_disease_prev i.eventdate i.regioncode detect_index infection lgdp_pc lpop pop_density

margins, at(vdem_libdem=(0.1(0.05)1)) vce(bootstrap, reps(100) seed(123) nodrop)

marginsplot


**************************************************
******* ADDITIONAL RESULTS NOT REPORTED **********
**************************************************

//////////////////////
* LINEAR REGRESSIONS *
//////////////////////

* Linear Regression for Cummulative Deaths/Cases as on March 1, 2021 *

// Deaths //

local x_d share_older health_exp_pc resp_disease_prev i.eventdate i.regioncode detect_index infection lgdp_pc lpop pop_density


foreach x in vdem_libdem eiu_dem_score i.dem_class polity  {
	eststo clear
	_eststo: reg deaths_cum_log `x'  `x_d' if date == "01/03/2021"
	outreg2  using cum_0, keep(vdem_libdem eiu_dem_score i.dem_class polity share_older healthcare_qual health_exp_pc resp_disease_prev detect_index infection lgdp_pc lpop pop_density) excel
}

// Cases //

local x_c share_older health_exp_pc resp_disease_prev i.eventdate i.regioncode detect_index infection lgdp_pc lpop pop_density


foreach x in vdem_libdem eiu_dem_score i.dem_class polity  {
	eststo clear
	_eststo: reg lcases `x'  `x_c' if date == "01/03/2021"
	outreg2  using cum_0, keep(vdem_libdem eiu_dem_score i.dem_class polity share_older healthcare_qual health_exp_pc resp_disease_prev detect_index infection lgdp_pc lpop pop_density) excel

}

////////////////////////////////////////////////////////////////////////
* CHECKING FOR NON-LINEAR RELATIONSHIP b/w DEMOCRACY SCORES and DEATHS *
////////////////////////////////////////////////////////////////////////


* The code in this section was used to check for the non-linear relatiosnhip between democracy scores and log(deaths) *

* scatter for daily deaths and democracy scores *

twoway scatter ldeaths eiu_dem_score || fpfitci ldeaths eiu_dem_score

twoway scatter ldeaths eiu_dem_score || fpfitci ldeaths eiu_dem_score, by(dem_class)

twoway scatter ldeaths vdem_libdem  || fpfitci ldeaths vdem_libdem

twoway scatter ldeaths polity  || fpfitci ldeaths polity

* scatter for daily cases and democracy scores *

twoway scatter lcases eiu_dem_score || fpfitci ldeaths eiu_dem_score

twoway scatter lcases eiu_dem_score || fpfitci ldeaths eiu_dem_score, by(dem_class)

twoway scatter lcases vdem_libdem  || fpfitci ldeaths vdem_libdem

twoway scatter lcases polity  || fpfitci ldeaths polity



* Fractional Polynomial Regression to allow for non-linear relationship between democracy scores and ldeaths/ lcases *

// Deaths //

local x_d share_older health_exp_pc resp_disease_prev i.eventdate i.regioncode detect_index infection lgdp_pc lpop pop_density

foreach x in vdem_libdem eiu_dem_score  {
	eststo clear
	_eststo: fp<`x'>, scale: reg ldeaths <`x'>  `x_d', vce(cluster country_code)
	fp plot, residuals(none)
	graph save frac_`x'_ld.gph, replace
	outreg2  using frac, keep(`x'_1 `x'_2 i.dem_class share_older healthcare_qual health_exp_pc resp_disease_prev detect_index infection lgdp_pc lpop pop_density) excel
	drop `x'_1 `x'_2
}


// Cases //

local x_c share_older health_exp_pc resp_disease_prev i.eventdate i.regioncode detect_index infection lgdp_pc lpop pop_density


foreach x in vdem_libdem eiu_dem_score  {
	eststo clear
	_eststo: fp<`x'>, scale: reg lcases <`x'>  `x_c', vce(cluster country_code)
	fp plot, residuals(none)
	graph save frac_`x'_lc.gph, replace 
	outreg2  using frac, keep(`x'_1 `x'_2 i.dem_class share_older healthcare_qual health_exp_pc resp_disease_prev detect_index infection lgdp_pc lpop pop_density) excel

}

fp<polity>, scale: reg ldeaths <polity>  share_older health_exp_pc resp_disease_prev i.eventdate i.regioncode detect_index infection lgdp_pc lpop pop_density, vce(cluster country_code)


