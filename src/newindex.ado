  *! version 0.0.4 31MAY2023
  capture program drop newindex
  program define newindex, rclass
    version 12
    syntax varlist(min=1 max=1) [if] [in], ///
      z(real)             ///
      [                   ///
      NOTES               ///
      KEEPvars            ///
      DOTplot             ///
      BC(real 0.000001)   ///
      ]
     
    * Remove observations excluded by if and in
    marksample touse, novarlist
    quietly keep if `touse'
      
    * Tempvars
    tempvar mean_income
    tempvar var
    
    * Gen income (or var) only for those that are greater than zero
    quietly {
      gen `var' = `varlist' if `varlist' > 0 & !missing(`varlist')
        
      // Bottom-coded part 
      if (`bc' != 0.000001 & `bc' > 0) {
        tempvar counta
        
        *create counter of bottom-coded obs
        gen `counta'      = 1 if missing(`var')
        replace `counta'  = 1 if `var' < `bc'
        
        *replace values in estimating variable
        replace `var' = `bc' if missing(`var') 
        replace `var' = `bc' if `var' < `bc'  
        
        * local counter of bottom-coded changes
        count if `counta' == 1
        local NBC = r(N)
      } 
      
      count if `varlist' <= 0
      local NN = r(N)
    }
    
    capture drop Z W censored C P I
    quietly {
      * Generate the variables
      // W Index
      gen Z = `z'    
      gen W  = Z / `var'        if `var' > 0 & !missing(`var')
      // C Index
      gen censored     = `var'  if `var' <  Z
      replace censored = Z      if `var' >= Z
      gen C = (Z / censored)
      // P Index
      gen P = (Z / censored) - 1
      // I Index
      quietly svy: mean `var'
      matrix define mat_mean = r(table)
      local mat_mean = r(table)[1,1]
      gen I = `mat_mean' / `var'
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
      
      svy: mean W C P I `if' `in'
      
      * Message: general note for each index
      if !missing("`notes'") {
        display as result "W Index is defined as: the factor by which `varlist' should be multiplied to reach z."   
        display as result "C Index is defined as: the average factor by which `varlist' needs to be multiplied to attain the standard of living defined by the threshold, with no increase for people above the threshold z."  
        display as result "P Index is defined as: C - 1 which is the average growth rate needed to attain the standard of livign defined by the threshold z."     
        display as result "I Index is defined as: the inequality index which is the average factor by which `varlist' must be multiplied to get to the mean `varlist'."         
      }     
      
      * Message: Count 0 and not bottomcoded
      if (`NN' != 0) & missing(`bc') {
        display as error "Warning: There are a total of `NN' observations with 0s or negatives in your data and they have been removed from the estimations. Please check the distribution of `varlist'."
      }
      
      * Message: Count 0 and bottom coded
      else if (`NN' != 0) & (`bc' != 0.000001) {
        display as error "Warning: There are a total of `NN' observations with 0s or negatives in your data. `NBC' were bottom coded and have been set to `bc'. Please check the distribution of `varlist'."
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

    
    
