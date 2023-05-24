*! version 0.0.1 20MAY2023
capture program drop senindex
program define senindex, rclass
  version 12
  syntax varlist(min=1 max=1) [aw iw] [if] [in], z(real) ///
    [DOTplot KEEPvars NONOTES]
  
  * Setup vce 
  * Prompt the user to use svyset: Parameters to set

  * Check if income is 0 or negative
  // Anything that is zero or negative, set to the smallest positive value
  // Option 1: Warning: x many observations out of _N were set to ... because ...
  // Option 2: Value of 0 have been dropped from the calculations
  // Option 3: Winsorized option
  
  * Remove observations excluded by if and in
  marksample touse,  novarlist
  keep if `touse'
    
  * Tempvars
  tempvar mean_income
  
  quietly {
    count if `varlist' <= 0
    local NN = r(N)
  }
  
  capture drop Z W censored C P I
  * Generate the variables
  // W Index
  gen Z = `z'    
  gen W  = Z / `varlist'    if !missing(`varlist')
  // C Index
  gen censored = `varlist'  if `varlist' <  Z
  replace censored = Z      if `varlist' >= Z
  gen C = (Z / censored)
  // P Index
  gen P = (Z / censored) - 1
  // I Index
  quietly egen `mean_income' = mean(`varlist') 
  gen I = `mean_income' / `varlist'
 
  * Label vars
  label var Z         "Reference Income"
  label var W         "W Index"  
  label var censored  "Censored"
  label var C         "C Index"  
  label var P         "P Index"
  label var I         "I Index"
  
  * Label varlist
  local lbl : variable label `varlist'
  
  * Check if z is positive
  if `z' > 0 {
    * Mean estimates
    if (`NN' != 0) {
      display as result "There were a total of `NN' observations with income 0 in your data."
      display as result "Please check your `varlist' variable."
    }
    display as text _n(2) "Distribution-Sensitive Index for var: `varlist'"
    
    svy: mean W C P I [`weight' `exp'] `if'
    
    if "`nonotes'" == "" {
      display as result "W Index is defined as: the factor by which `varlist' should be multiplied to reach z."   
      display as result "C Index is defined as: the average factor by which `varlist' needs to be multiplied to attain the standard of living defined by the threshold, with no increase for people above the threshold z."  
      display as result "P Index is defined as: C - 1 which is the average growth rate needed to attain the standard of livign defined by the threshold z."     
      display as result "I Index is defined as: the inequality index which is the average factor by which `varlist' must be multiplied to get to the mean `varlist'."   
      display as result "Please refer to Kraay et al. (2023) for a detailed discussion on the estimation of each index."        
    }     
  } 
  
  else if `z' <= 0 {
    noisily display as error "Negative z is not allowed."
    error 198
  }

  * If dot plot
  if !missing("`dotplot'") {
    twoway scatter `varlist' W, msize(small) title("Individual contribution (ratio)" "as a function of `lbl'", size(medsmall))
  }
  
  * Matrix Return
  matrix define dis_table = r(table)
  local indeces "W C P I"
  local i = 1
  foreach index of local indeces {
    local mean_`index'  = dis_table[1,`i']
    local se_`index'    = dis_table[2,`i']
    local pval_`index'  = dis_table[4,`i']
    
    local ++i
    
    * Return values
    return scalar mean_`index' = `mean_`index''
    return scalar se_`index'   = `se_`index''
    return scalar pval_`index' = `pval_`index''
  }
    
  * Drop variables
  if missing("`keepvars'") {
    capture drop Z W censored C P I
  } 
  
end

  
  
