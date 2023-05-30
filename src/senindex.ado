*! version 0.0.2 29MAY2023
capture program drop senindex
program define senindex, rclass
  version 12
  syntax varlist(min=1 max=1) [aw iw pw] [if] [in], z(real) ///
    [NOTES KEEPvars BOTTOMcoded DOTplot]
   
  * Remove observations excluded by if and in
  marksample touse, novarlist
  quietly keep if `touse'
    
  * Tempvars
  tempvar mean_income
  tempvar var
  
  * Gen income (or var) only for those that are greater than zero
  quietly {
    gen `var' = `varlist' if `varlist' > 0 & !missing(`varlist')
    
    if !missing("`bottomcoded'") {
      tempvar p1
      
      quietly sum `varlist', detail
      local bc = `r(p1)'
      gen `p1' = `r(p1)'
      replace `var' = `r(p1)' if missing(`var')
    } 
    
    count if `varlist' <= 0
    local NN = r(N)
  }
  
  capture drop Z W censored C P I
  quietly {
    * Generate the variables
    // W Index
    gen Z = `z'    
    gen W  = Z / `var'    if `var' > 0 & !missing(`var')
    // C Index
    gen censored     = `var'  if `var' <  Z
    replace censored = Z      if `var' >= Z
    gen C = (Z / censored)
    // P Index
    gen P = (Z / censored) - 1
    // I Index
    quietly egen `mean_income' = mean(`var') 
    gen I = `mean_income' / `var'
  }
  
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
    display as text "Distribution-Sensitive Index for var: `varlist'"
    
    svy: mean W C P I [`weight' `exp'] `if' `in'
    
    * Message: general note for each index
    if !missing("`notes'") {
      display as result "W Index is defined as: the factor by which `varlist' should be multiplied to reach z."   
      display as result "C Index is defined as: the average factor by which `varlist' needs to be multiplied to attain the standard of living defined by the threshold, with no increase for people above the threshold z."  
      display as result "P Index is defined as: C - 1 which is the average growth rate needed to attain the standard of livign defined by the threshold z."     
      display as result "I Index is defined as: the inequality index which is the average factor by which `varlist' must be multiplied to get to the mean `varlist'."         
    }     
    
    * Message: Count 0 and not bottomcoded
    if (`NN' != 0 & missing("`bottomcoded'")) {
      display as error "Warning: There are a total of `NN' observations with 0s or negatives in your data and they have been removed from the estimations. Please check the distribution of `varlist'."
    }
    
    * Message: Count 0 and bottom coded
    else if (`NN' != 0 & !missing("`bottomcoded'")) {
      display as error "Warning: There are a total of `NN' observations with 0s or negatives in your data and they have been set to `bc' (1st percentile). Please check the distribution of `varlist'."
    }
    
    * Message: Paper notes
    display as result "Note: These indices correspond to the four welfare, poverty, and inequality indices discussed in Section 2 of Kraay (r) al. (2023)." 
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

  
  
