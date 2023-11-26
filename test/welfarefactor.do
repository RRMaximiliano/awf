* ------------------------------------------------------------------------------
* paths and load adofile if not installed from ssc 
* ------------------------------------------------------------------------------
global path = "C:/Users/ifyou/Documents/GitHub/packages-stata/welfarefactor"
global data = "${path}/data"
global src  = "${path}/src"

* run ado file
run "${src}/welfarefactor.ado"

* From github using net install as well
// net install welfarefactor, from("https://raw.githubusercontent.com/rrmaximiliano/welfarefactor/main") replace force 

* ------------------------------------------------------------------------------
* Test example
* ------------------------------------------------------------------------------

/*
 Options
 - z: reference income value 
 - bc: bottom coded value
 - winsor: percentile inrange(1,99)
 - notes: display notes
 - keep: keep generated variables
 - dotplot: dot plot (VAR vs W index)
*/

* Example 1
* ------------------------------------------------------------------------------
* load data
use "${data}/NLSS2011_cons.dta", clear 

* svyset
svyset xhpsu [pweight=wt_ind], strata(xstra)

* First with no missings and no zeroes
welfarefactor totcons_pc_7, z(45000) 

* Make some missings
replace totcons_pc_7 = . in 36/80     // 45 to missing

* This will use only positive value (the original dataset didn't have negatives)
* The missing are not taken into account
welfarefactor totcons_pc_7, z(45000)

* Make some 0s
replace totcons_pc_7 = 0 in 100/119   // 20 to 0s

* This will dropped the 0s observations (the original dataset didn't have 0s)
* These obs are not taken into account
welfarefactor totcons_pc_7, z(45000)

* ------------------------------------------------------------------------------
* Example 2: Using BC and BCP
* ------------------------------------------------------------------------------

* Errors of two options
welfarefactor totcons_pc_7, z(45000) bc(100) winsor(0.5)

* Using BC
* ------------------------------------------------------------------------------
* There are 30 obs in this dataset with <= 6000 -- We will use them to check 
* the bottom coded exercise. As a reference, we have the following:
* 5988 observations
* 45 with missings (totcons_pc_7)
* 20 with 0s.
* 30 with values less than equal to 6000 (20 0s + 10 positives)
* Those 10 will be BC to 6000
welfarefactor totcons_pc_7, z(45000) bc(6000) 

* Using BCP (from 1 to 100)
welfarefactor totcons_pc_7, z(45000) winsor(5) 


* ------------------------------------------------------------------------------ 
* Example 3
* ------------------------------------------------------------------------------
* load data
use "${data}/SEPOV.dta", clear

* index
welfarefactor pcexp_r, z(129.19)
welfarefactor pcexp_r, z(129.19) keep 
welfarefactor pcexp_r, z(129.19) keep notes

* replace obs to 0
replace pcexp_r = 0 in 1/20
welfarefactor pcexp_r, z(129.19)
welfarefactor pcexp_r, z(129.19) bc(100) keep 
welfarefactor pcexp_r, z(129.19) winsor(10) keep 

* Using an example dataset to generate diff SEs example (with jacknife)
* ------------------------------------------------------------------------------

* load data
webuse stage5a_jkw, clear

* set dummy svyset and generate income
svyset [pweight=pw], jkrweight(jkw_*) vce(jackknife)
gen income = runiformint(1,10000)

* index
welfarefactor income, z(2000) keep 

* replace obs to 0
replace income = 0 in 1/20
welfarefactor income, z(2000) keep 
welfarefactor income, z(2000) bc(100) 
welfarefactor income, z(2000) winsor(1) 
