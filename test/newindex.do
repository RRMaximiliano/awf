* ------------------------------------------------------------------------------
* paths and load adofile if not installed from ssc 
* ------------------------------------------------------------------------------
global path = "C:/Users/ifyou/Documents/GitHub/packages-stata/senindex"
global data = "${path}/data"
global src  = "${path}/src"

* run ado file
run "${src}/newindex.ado"

* From github using net install as well
// net install newindex, from("https://raw.githubusercontent.com/rrmaximiliano/newindex/main") replace force 

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
newindex totcons_pc_7, z(45000)             // Total HH consumption
newindex food_pc_7,    z(20000)             // Food consumption which contains two obs with 0s.
newindex food_pc_7,    z(20000) bc(100)     // Bottom coded those two obs.
 
* Example 2
* ------------------------------------------------------------------------------
* load data
use "${data}/SEPOV.dta", clear

* index
newindex pcexp_r, z(129.19)
newindex pcexp_r, z(129.19) keep 
newindex pcexp_r, z(129.19) keep notes

* replace obs to 0
replace pcexp_r = 0 in 1/20
newindex pcexp_r, z(129.19) keep 
newindex pcexp_r, z(129.19) bc(100) keep 

* Using an example dataset to generate diff SEs example (with jacknife)
* ------------------------------------------------------------------------------

* load data
webuse stage5a_jkw, clear

* set dummy svyset and generate income
svyset [pweight=pw], jkrweight(jkw_*) vce(jackknife)
gen income = runiformint(1,10000)

* index
newindex income, z(2000) keep notes

* replace obs to 0
replace income = 0 in 1/20
newindex income, z(2000) keep 
newindex income, z(2000) keep bottom 
