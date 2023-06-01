* ------------------------------------------------------------------------------
* paths and load adofile if not installed from ssc 
* ------------------------------------------------------------------------------
global path = "C:/Users/ifyou/Documents/GitHub/packages-stata/welfarefactor"
global data = "${path}/data"
global src  = "${path}/src"

* run ado file
// run "${src}/welfarefactor.ado"

* From github using net install as well
net install welfarefactor, from("https://raw.githubusercontent.com/rrmaximiliano/welfarefactor/main") replace force 

* ------------------------------------------------------------------------------
* Test example
* ------------------------------------------------------------------------------

* Example 1
* ------------------------------------------------------------------------------
* load data
use "${data}/NLSS2011_cons.dta", clear 

* svyset
svyset xhpsu [pweight=wt_ind], strata(xstra)

* index
welfarefactor totcons_pc_7, z(45000)             // Total HH consumption
welfarefactor food_pc_7,    z(20000)             // Food consumption which contains two obs with 0s.
welfarefactor food_pc_7,    z(20000) bc(100)     // Bottom coded those two obs.
 
* Example 2
* ------------------------------------------------------------------------------
* load data
use "${data}/SEPOV.dta", clear

* index
welfarefactor pcexp_r, z(129.19)
welfarefactor pcexp_r, z(129.19) keep 
welfarefactor pcexp_r, z(129.19) keep notes

* replace obs to 0
replace pcexp_r = 0 in 1/20
welfarefactor pcexp_r, z(129.19) keep
welfarefactor pcexp_r, z(129.19) bc(100) keep 

* Using an example dataset to generate diff SEs example (with jacknife)
* ------------------------------------------------------------------------------

* load data
webuse stage5a_jkw, clear

* set dummy svyset and generate income
svyset [pweight=pw], jkrweight(jkw_*) vce(jackknife)
gen income = runiformint(1,10000)

* index
welfarefactor income, z(2000) keep notes

* replace obs to 0
replace income = 0 in 1/20
welfarefactor income, z(2000) keep 
welfarefactor income, z(2000) keep bottom 
