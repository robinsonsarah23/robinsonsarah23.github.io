
if "`c(username)'"=="alisatns"{
do "/Users/`c(username)'/Dropbox/Projects/Tax Policy Determinants/Do files/0_Set_Directories.do"
set linesize 255
}
if "`c(username)'"=="SarahRobinson"{
do "/Users/`c(username)'/Dropbox/Tax Policy Determinants/Do files/0_Set_Directories.do"
set linesize 130
}
clear all
set more off
cap log close




cap log using "$dir_tex/2_OverviewGraphs.log", replace
 

****************************************************************************
* DESCRIPTION
* 
* This file creates graphs summarizing the trends in tax rates/policies and changes 
* over time. CLEANER VERSION TO MAKE LIVES EASIER
* 
* Tax rates of focus:
*   - Personal income tax, top MTR
*   - Corporate income tax, top MTR
*   - Sales tax
*   - Cigarette tax (nominal & real)
*   - Alcohol wine tax (nominal & real)
* 
* States are divided two ways:
*   - safe_party -- Safe R, Safe D, Swing (based on 2012+ legislatures, stable over time)
*   - leg_pty -- House/Sen R, House/Sen D, Split (not stable over time)
*
* Output: Dropbox > Graphs > Overview Graphs
*
* Requires: net install grc1leg2
*
****************************************************************************



use  "$dir_data/STATE_ALL.dta"

replace safe_party=pty_2016 /* use 2016 presidential tallies for simplicity */
* Formatting for party names
replace safe_party = "Safe Republican" if safe_party=="Republican"
replace safe_party = "Safe Democratic" if safe_party=="Democrat"

replace leg_pty = "Republican Legislatures" if leg_pty=="Republican"
replace leg_pty = "Democratic Legislatures" if leg_pty=="Democrat"


* Ways of categorizing states 
local categs  leg_pty safe_party // categories to loop over, can add more here
local safe_party_types `" "Safe Democratic" "Swing" "Safe Republican" "' 
local leg_pty_types `" "Democratic Legislatures" "Other" "Republican Legislatures"' 


* Tax rates of focus
local taxes pincome_top_tax_rate corporate_income_tax_rate sales_tax_rate gasoline_tax_rate ///
cigarette_tax_nom cigarette_tax alcohol_wine_tax_nom alcohol_wine_tax 

local n_taxes : word count `taxes'


* Formatting for change variables
label variable pincome_top_tax_rate_ichg "Change in top personal income tax (pct pts)"
label variable corporate_income_tax_rate_ichg "Change in corporate tax (pct pts)"
label variable sales_tax_rate_ichg "Change in sales tax (pct pts)"
label variable cigarette_tax_ichg "Change in cigarette tax (2020$ per pack)"
label variable alcohol_wine_tax_ichg "Change in wine tax (2020$ per gallon)"
label variable gasoline_tax_rate_ichg "Change in gasoline tax (2020$ per gallon)"


* Dummy variables for changes loop
gen cigarette_tax_nom_ichg = 1
gen cigarette_tax_nom_echg = 1
gen alcohol_wine_tax_nom_ichg = 1
gen alcohol_wine_tax_nom_echg = 1



****************************************************************************
* Graph of level over time
****************************************************************************

* Max and tick values
local mins  0  0  0 0  0  0  0  0
local maxs 20 15 10 1  5  5  3  7.5
local ticks 5  5 2.5 0.25 1  1  1  1.5

*** Creating graph ***
* Looping over tax rate
forval i=1/`n_taxes' {

	local var `: word `i' of `taxes''
	local varlabel: var label `var'
	local tick `: word `i' of `ticks''
	local max `: word `i' of `maxs''
	local min `: word `i' of `mins''
	
	
	if "`var'"=="pincome_top_tax_rate"{
	local fed_changes 1982 1987 1988 1991 1993 2001 2002 2003 2013 2018, lcolor(gs8)
	}
	if "`var'"=="corporate_income_tax_rate"{
	local fed_changes 1979 1987 1988 1993 2018, lcolor(gs8)
	}
		if "`var'"=="sales_tax_rate"{
	local fed_changes 
	}
		if "`var'"=="cigarette_tax_nom" | "`var'"=="cigarette_tax"  {
	local fed_changes  1992 1993 2000 2002 2009, lcolor(gs8)
	}
			if "`var'"=="alcohol_wine_tax_nom" | "`var'"=="alcohol_wine_tax"  {
	local fed_changes 1991 2018, lcolor(gs8)
	}
	
	
	* Looping over way of categorizing states
	foreach categ of local categs { 
	
		* Looping over parties (1=D, 2=neither, 3=R)
		forval j=1/3 {
			
			local pty `:word `j' of ``categ'_types''
		
			* Maximum rate by year
			bysort year: egen max = max(cond(`categ'=="`pty'",`var',.))
			
			* 75th percentile rate by year, conditional on being greater than zero
			bysort year: egen uqt = pctile(cond(`var'>0 & `categ'=="`pty'",`var',.)), p(75)
			
			* Median rate by year, conditional on being greater than zero
			bysort year: egen med = median(cond(`var'>0 & `categ'=="`pty'",`var',.))
			
			* Mean rate by year, conditional on being greater than zero
			bysort year: egen mean = mean(cond(`var'>0 & `categ'=="`pty'",`var',.))
			
			* 25th percentile rate by year, conditional on being greater than zero
			bysort year: egen lqt = pctile(cond(`var'>0 & `categ'=="`pty'",`var',.)), p(25)
			
			* Minimum rate by year, conditional on being greater than zero
			bysort year: egen min = min(cond(`var'>0 & `categ'=="`pty'",`var',.))
			
			* Graph for single party
			twoway rarea max min year if max!=., sort lwidth(none) fcolor(navy) fintensity(20) || ///
			rarea uqt lqt year if max!=., sort lwidth(none) fcolor(navy) fintensity(45) || ///
			connected med year if max!=., mcolor(navy) msize(medsmall) lcolor(navy) msymbol(diamond_hollow) || ///
			connected mean year if max!=., mcolor(maroon) msize(medsmall) lcolor(maroon)  ///
				xline(1981, lwidth(4.4) lcolor(gray*0.15)) ///
				xline(1990.5, lwidth(2.2) lcolor(gray*0.15)) ///
				xline(2001.5, lwidth(2.2) lcolor(gray*0.15)) ///
				xline(2008, lwidth(4.4) lcolor(gray*0.15)) /// xline(1980 1982 1990 1991 2001 2002 2007 2009, lcolor(red) lwidth(vthin)) ///
				xline(`fed_changes') ///
				legend(order(4 "Mean" 3 "Median" 2 "75th / 25th pctile" 1 "Max / Min"  ) row(1) region(col(white))) ///
				graphregion(color(white)) ///
				bgcolor(white) ///
				ytitle("`varlabel'", height(3) size(medlarge)) ///
				xtitle("Year", size(medlarge)) ///
				yscale(range(`min' `max')) ///
				ylabel(`min'(`tick')`max', ang(h) labsize(medlarge)) ///
				xlabel(1970(10)2020, labsize(medlarge)) ///
				title("`pty' States", color(black)) ///
				name("party`j'", replace)
			
			drop max uqt med mean lqt min
		}
		
		* Main graph with 2 state groups
		grc1leg2 party1 party3, ///
			row(1) ///
			span ///
			ring(10) ///
			graphregion(color(white)) ///
			name("main", replace)
		graph display main, xsize(10) ysize(4)
		graph export "$dir_graphs/Overview Graphs/overall_level_`var'_`categ'.pdf", replace
		
		* Appendix graph with 3 state groups
		grc1leg2 party1 party2 party3, ///
			row(1) ///
			span ///
			ring(10) ///
			graphregion(color(white)) ///
			name("appendix", replace)
		graph display appendix, xsize(15) ysize(4)
		graph export "$dir_graphs/Overview Graphs/overall_level_`var'_`categ'_appx.pdf", replace

	}
}



****************************************************************************
* Graph of absolute increases/decreases over time (intensive margin only)
****************************************************************************
 
* Max values for changes
local labelmaxs  3 6 2   2   2 2.5 2.5
local showmaxs 3.2 6 2 2.2 2.2 2.5 2.5

*** Creating graph ***
* Looping over tax rate
forval i=1/`n_taxes' {
	
	local var `: word `i' of `taxes''
	local varlabel: var label `var'
	local varlabelichg: var label `var'_ichg
	local max `: word `i' of `labelmaxs''
	local min = `max' * -1
	local tick = `max' / 2
	local showmax `: word `i' of `showmaxs''
	local showmin = `showmax' * -1
	
	if "`var'"=="pincome_top_tax_rate"{
	local fed_changes 1982 1987 1988 1991 1993 2001 2002 2003 2013 2018, lcolor(gs8)
	}
	if "`var'"=="corporate_income_tax_rate"{
	local fed_changes 1979 1987 1988 1993 2018, lcolor(gs8)
	}
		if "`var'"=="sales_tax_rate"{
	local fed_changes 
	}
		if "`var'"=="cigarette_tax_nom" | "`var'"=="cigarette_tax"  {
	local fed_changes  1992 1993 2000 2002 2009, lcolor(gs8)
	}
			if "`var'"=="alcohol_wine_tax_nom" | "`var'"=="alcohol_wine_tax"  {
	local fed_changes 1991 2018, lcolor(gs8)
	}
				if "`var'"=="gasoline_tax_rate_nom" | "`var'"=="gasoline_tax_rate"  {
	local fed_changes 1983 1990 1993, lcolor(gs8)
	}
	
	* Creating dummy real change variables
	if ("`var'"!="cigarette_tax" & "`var'"!="alcohol_wine_tax") {
		gen `var'_real=1
	}
	
	
	* Looping over way of categorizing states
	foreach categ of local categs { 
	
		* Looping over parties (1=D, 2=neither, 3=R)
		forval j=1/3 {
			
			local pty `:word `j' of ``categ'_types''
		
			* Out of all the states in category that already had a tax, what percent increased/decreased the tax rate (intensive margin only)
			bysort year: egen total = total(cond(`categ'=="`pty'" & `var'>0 & `var'!=. & `var'_echg==0,1,.)), missing
			bysort year: egen inc = total(cond(`categ'=="`pty'" & `var'_ichg!=. & `var'_ichg>0 & `var'_echg==0 & `var'_real==1,1,.))
			bysort year: egen dec = total(cond(`categ'=="`pty'" & `var'_ichg!=. & `var'_ichg<0 & `var'_echg==0 & `var'_real==1,1,.))
			gen incp = inc * 100 / total
			gen decp = dec * -100 / total

			* Average absolute increase/decrease conditional on there being an intensive margin change
			bysort year: egen avginc = mean(cond(`categ'=="`pty'" & `var'_ichg>0 & `var'_echg==0 & `var'_real==1,`var'_ichg,.))
			replace avginc = 0 if avginc == .
			bysort year: egen avgdec = mean(cond(`categ'=="`pty'" & `var'_ichg<0 & `var'_echg==0 & `var'_real==1,`var'_ichg,.))
			replace avgdec = 0 if avgdec == .

			* Graph
			twoway bar incp year if total !=., barw(.9) lwidth(none) fcolor(emerald) fintensity(40) yaxis(1) || ///
			bar decp year if total !=., barw(.9) lwidth(none) fcolor(cranberry) fintensity(40) yaxis(1) || ///
			connected avginc year if total !=., mcolor(emerald) lcolor(emerald*1.2)  msize(small) yaxis(2) msymbol(T) || ///
			connected avgdec year if total !=., mcolor(cranberry)  lcolor(cranberry*1.2) msize(small) yaxis(2) ///
				xline(1981, lwidth(3.8) lcolor(gray*0.15)) ///
				xline(1990.5, lwidth(1.9) lcolor(gray*0.15)) ///
				xline(2001.5, lwidth(1.9) lcolor(gray*0.15)) ///
				xline(2008, lwidth(3.8) lcolor(gray*0.15)) /// xline(1980 1982 1990 1991 2001 2002 2007 2009, lcolor(red) lwidth(vthin)) ///
				xline(`fed_changes') ///
				yline(0, lcolor(gray)) ///
				legend(order(9 "{it: Left axis}" 10 "{it: Right axis}"  1 "% of legislatures that increased tax" 3 "Mean absolute increase" 2 "% of legislatures that decreased tax" 4 "Mean absolute decrease" ) row(3) region(col(white))) ///
				graphregion(color(white)) ///
				bgcolor(white) ///
				ytitle("`varlabelichg'", axis(2) size(medlarge)) ///
				ytitle("% of legislatures that increased (decreased) tax", axis(1) size(medlarge)) ///
				ylabel(`min'(`tick')`max', axis(2) ang(h)  labsize(medlarge)) ///
				yscale(range(`showmin' `showmax') axis(2)) ///
				ylabel(-100(50)100, axis(1) ang(h) nogrid labsize(medlarge)) ///
				title("`pty' States", color(black)) ///
				xlabel(1970(10)2020, labsize(medlarge)) ///
				xtitle("Year", size(medlarge)) ///
				name("party`j'", replace)
				
			drop total inc dec incp decp avginc avgdec
		}
		
		* Main graph with 2 state groups
		grc1leg2 party1 party3, ///
			row(1) ///
			span ///
			ring(10) ///
			graphregion(color(white)) ///
			name("main", replace)
		graph display main, xsize(10) ysize(5)
		graph export "$dir_graphs/Overview Graphs/overall_chng_`var'_`categ'.pdf", replace 
		
		* Appendix graph with 3 state groups
		grc1leg2 party1 party2 party3, ///
			row(1) ///
			span ///
			ring(10) ///
			graphregion(color(white)) ///
			name("appendix", replace)
		graph display appendix, xsize(15) ysize(5)
		graph export "$dir_graphs/Overview Graphs/overall_chng_`var'_`categ'_appx.pdf", replace 
	}
		
}



************************************************************
***** POLARIZATION GRAPHS ******
************************************************************

clear
use  "$dir_data/STATE_ALL.dta"

replace safe_party=pty_2016 /* use 2016 presidential tallies for simplicity */

* Formatting for party names
replace safe_party = "Safe Republican" if safe_party=="Republican"
replace safe_party = "Safe Democratic" if safe_party=="Democrat"

replace leg_pty = "Republican Legislatures" if leg_pty=="Republican"
replace leg_pty = "Democratic Legislatures" if leg_pty=="Democrat"


* Ways of categorizing states 
local categs  leg_pty safe_party // categories to loop over, can add more here
local safe_party_types `" "Safe Democrat" "Swing" "Safe Republican" "' 
local leg_pty_types `" "Democratic Legislatures" "Other" "Republican Legislatures"' 


* Tax rates of focus
local taxes pincome_top_tax_rate corporate_income_tax_rate sales_tax_rate gasoline_tax_rate ///
cigarette_tax_nom cigarette_tax alcohol_wine_tax_nom alcohol_wine_tax

local n_taxes : word count `taxes'


* Formatting for change variables
label variable pincome_top_tax_rate_ichg "Change in top personal income tax (pct pts)"
label variable corporate_income_tax_rate_ichg "Change in corporate tax (pct pts)"
label variable sales_tax_rate_ichg "Change in sales tax (pct pts)"
label variable cigarette_tax_ichg "Change in cigarette tax (2020$ per pack)"
label variable alcohol_wine_tax_ichg "Change in wine tax (2020$ per gallon)"
label variable gasoline_tax_rate_ichg "Change in gasoline tax (2020$ per gallon)"


* Dummy variables for changes loop
gen cigarette_tax_nom_ichg = 1
gen cigarette_tax_nom_echg = 1
gen alcohol_wine_tax_nom_ichg = 1
gen alcohol_wine_tax_nom_echg = 1

if "`var'"=="pincome_top_tax_rate"{
	local fed_changes 1982 1987 1988 1991 1993 2001 2002 2003 2013 2018, lcolor(gs8)
	}
	if "`var'"=="corporate_income_tax_rate"{
	local fed_changes 1979 1987 1988 1993 2018, lcolor(gs8)
	}
		if "`var'"=="sales_tax_rate"{
	local fed_changes 
	}
		if "`var'"=="cigarette_tax_nom" | "`var'"=="cigarette_tax"  {
	local fed_changes  1992 1993 2000 2002 2009, lcolor(gs8)
	}
			if "`var'"=="alcohol_wine_tax_nom" | "`var'"=="alcohol_wine_tax"  {
	local fed_changes 1991 2018, lcolor(gs8)
	}
				if "`var'"=="gasoline_tax_rate_nom" | "`var'"=="gasoline_tax_rate"  {
	local fed_changes 1983 1990 1993 , lcolor(gs8)
	}


****************************************************************************
* Graph of Republican-Democrat difference over time
****************************************************************************

gen year2=ceil(year/5)*5

* Max and tick values
local mins  -4  -3  -2  -0.5   -1    -2  -2
local maxs   6   5   3   0.5   3     2  4
local ticks 1    1  0.5  0.1  0.5   0.5  1

*** Creating graph ***
* Looping over tax rate
forval i=1/`n_taxes' {

	local var `: word `i' of `taxes''
	local varlabel: var label `var'
	local tick `: word `i' of `ticks''
	local max `: word `i' of `maxs''
	local min `: word `i' of `mins''
	
	if "`var'"=="pincome_top_tax_rate"{
	local fed_changes 1982 1987 1988 1991 1993 2001 2002 2003 2013 2018, lcolor(gs8)
	}
	if "`var'"=="corporate_income_tax_rate"{
	local fed_changes 1979 1987 1988 1993 2018, lcolor(gs8)
	}
		if "`var'"=="sales_tax_rate"{
	local fed_changes 
	}
		if "`var'"=="cigarette_tax_nom" | "`var'"=="cigarette_tax"  {
	local fed_changes  1992 1993 2000 2002 2009, lcolor(gs8)
	}
			if "`var'"=="alcohol_wine_tax_nom" | "`var'"=="alcohol_wine_tax"  {
	local fed_changes 1991 2018, lcolor(gs8)
	}
	
	* Looping over way of categorizing states
	foreach categ of local categs { 
	*local categ leg_pty
		* Looping over parties (1=D, 2=neither, 3=R)
		forval j=1/3 {
			
			local pty `:word `j' of ``categ'_types''
		
			* Maximum rate by year
			bysort year2: egen max_`j' = max(cond(`categ'=="`pty'",`var',.))
			
			* 75th percentile rate by year, conditional on being greater than zero
			bysort year2: egen uqt_`j' = pctile(cond(`var'>0 & `categ'=="`pty'",`var',.)), p(75)
			
			* Median rate by year, conditional on being greater than zero
			bysort year2: egen med_`j' = median(cond(`var'>0 & `categ'=="`pty'",`var',.))
			
			* Mean rate by year, conditional on being greater than zero
			bysort year2: egen mean_`j' = mean(cond(`var'>0 & `categ'=="`pty'",`var',.))
			
			* 25th percentile rate by year, conditional on being greater than zero
			bysort year2: egen lqt_`j' = pctile(cond(`var'>0 & `categ'=="`pty'",`var',.)), p(25)
			
			* Minimum rate by year, conditional on being greater than zero
			bysort year2: egen min_`j' = min(cond(`var'>0 & `categ'=="`pty'",`var',.))

			* SD rate by year, conditional on being greater than zero
			bysort year2: egen sd_`j' = sd(cond(`var'>0 & `categ'=="`pty'",`var',.))
			
			* Count rate by year, conditional on being greater than zero
			bysort year2: egen n_`j' = count(cond(`var'>0 & `categ'=="`pty'",`var',.))
			
		}
		
		gen max=max_1-max_3
		gen uqt=uqt_1-uqt_3
		gen med=med_1-med_3
		gen mean=mean_1-mean_3
		gen lqt=lqt_1-lqt_3
		gen min=min_1-min_3
		gen sd=(sd_1^2/n_1+sd_3^2/n_3)^0.5
		gen lb=mean-sd*1.96
		gen ub=mean+sd*1.96
		drop max_* uqt_* med_* mean_* lqt_* min_* n_* sd_*
		
		
	
	* Graph of the differnce
	/*
			twoway rarea max min year if max!=., sort lwidth(none) fcolor(navy) fintensity(20) || ///
			rarea uqt lqt year if max!=., sort lwidth(none) fcolor(navy) fintensity(45) || ///
			connected med year if max!=., mcolor(navy) msize(medsmall) lcolor(navy) msymbol(diamond_hollow) || ///
			connected mean year if max!=., mcolor(maroon) msize(medsmall) lcolor(maroon)  ///
				xline(1981, lwidth(4.4) lcolor(gray*0.15)) ///
				xline(1990.5, lwidth(2.2) lcolor(gray*0.15)) ///
				xline(2001.5, lwidth(2.2) lcolor(gray*0.15)) ///
				xline(2008, lwidth(4.4) lcolor(gray*0.15)) /// xline(1980 1982 1990 1991 2001 2002 2007 2009, lcolor(red) lwidth(vthin)) ///
				legend(order(4 "Mean" 3 "Median" 2 "75th / 25th pctile" 1 "Max / Min"  ) row(1) region(col(white))) ///
				graphregion(color(white)) ///
				bgcolor(white) ///
				ytitle("`varlabel'", height(3) size(medlarge)) ///
				xtitle("Year", size(medlarge)) ///
				yscale(range(`min' `max')) ///
				ylabel(`min'(`tick')`max', ang(h) labsize(medlarge)) ///
				title("Difference between Democrat and  Republican States", color(black)) ///
				name("party`j'", replace) ///
				xlabel(1970(10)2020, labsize(medlarge)) 
				graph export "$dir_graphs/Overview Graphs/difference_`var'_`categ'.pdf", replace 
				*/
				
				 *connected med year if max!=., mcolor(navy) msize(medsmall) lcolor(navy) msymbol(diamond_hollow) || 
				 
				twoway connected mean year2 if max!=., mcolor(navy) msize(medsmall) color(navy)  ||  ///
				rcap lb ub year2 if max!=.,  color(navy)  ///
				xline(1981, lwidth(4.4) lcolor(gray*0.15)) ///
				xline(1990.5, lwidth(2.2) lcolor(gray*0.15)) ///
				xline(2001.5, lwidth(2.2) lcolor(gray*0.15)) ///
				xline(2008, lwidth(4.4) lcolor(gray*0.15)) /// xline(1980 1982 1990 1991 2001 2002 2007 2009, lcolor(red) lwidth(vthin)) ///
				xline(`fed_changes') ///
				yline(0, lcolor(maroon)) ///
				legend(order(1 "Mean" 2 "95% CI"   ) row(1) region(col(white))) ///
				graphregion(color(white)) ///
				bgcolor(white) ///
				ytitle("`varlabel'", height(3) size(medlarge)) ///
				xtitle("Year", size(medlarge)) ///
				yscale(range(`min' `max')) ///
				ylabel(`min'(`tick')`max', ang(h) labsize(medlarge)) ///
				title("Difference between Democratic and  Republican States", color(black)) ///
				name("party`j'", replace) ///
				xlabel(1970(10)2020, labsize(medlarge)) 
				graph export "$dir_graphs/Overview Graphs/difference_`var'_`categ'.pdf", replace 
				
				drop max uqt med mean lqt min sd lb ub 
	}
				
}



log close
