* ------------------------------------------------------------------------------
* paths and load adofile if not installed from ssc 
* ------------------------------------------------------------------------------
global path = "C:/Users/ifyou/Documents/GitHub/packages-stata/senindex/test"
global data = "${path}/data"
global src  = "${path}/src"

* run ado file
run "${sendindex}/senindex.ado"

* ------------------------------------------------------------------------------
* Test example
* ------------------------------------------------------------------------------

* Using Sepov data
* ------------------------------------------------------------------------------

* load data
use "${data}/SEPOV.dta", clear 

* index
senindex pcexp_r, z(129.19)
senindex pcexp_r, z(129.19) keep nonotes
senindex pcexp_r, z(129.19) keep nonotes dot


* Using dataset to generate diff SEs example (with jacknife)
* ------------------------------------------------------------------------------

* load data
webuse stage5a_jkw, clear

* set dummy svyset and generate income
svyset [pweight=pw], jkrweight(jkw_*) vce(jackknife)
gen income = runiformint(1,10000)

* index
senindex income, z(2000) keep nonotes
