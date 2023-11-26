  *! version 0.0.5 31MAY2023
  capture program drop welfarefactor
  program define welfarefactor, rclass
    version 12
    syntax varlist(min=1 max=1) [if] [in],  ///
      z(real)                               ///
      [                                     ///
      NOTES                                 ///
      KEEPvars                              ///
      DOTplot                               ///
      BC(numlist > 0)                       ///
      WINSOR(numlist min = 1 max = 99)      ///
      ]
         
    * Remove observations excluded by if and in
    marksample touse, novarlist
    quietly keep if `touse'
      
    * Tempvars
    tempvar var
    
		*Local to indicate if bc or winsor are included
		if missing("`bc'")            local BC_USED = 0
    else if !missing("`bc'")      local BC_USED = 1
		if missing("`winsor'")        local W_USED  = 0
    else if !missing("`winsor'")  local W_USED  = 1
    
    * Warning    
    if `BC_USED' == 1 & `W_USED' == 1 {
      display in w "bc() " in red "cannot be specified with" in w " winsor()" 
      exit 198
    }
          
    * Gen income (or var) only for those that are greater than zero
    quietly {
      gen `var' = `varlist' if `varlist' > 0 & !missing(`varlist')
      count if `varlist' <= 0
      local NN = r(N)
      count if `varlist' == 0
      local ZZ = r(N)  
      count if missing(`varlist')
      local MM = r(N)
    }
        
    // BC option
    if `BC_USED' == 1 {
      quietly {
        // Bottom-coded part 
        if (`BC_USED' == 1 & `bc' > 0) {
          tempvar counta
          
          *create counter of bottom-coded obs
          gen `counta'      = 0
          replace `counta'  = 1 if `var' < `bc' & !missing(`var')
          
          *replace values in estimating variable
          replace `var'     = `bc' if `counta' == 1
          
          * local counter of bottom-coded changes
          count if `counta' == 1
          local NBC = r(N)
        } 
      }
    }
    
    // Winsor option
    if `W_USED' == 1 {
      if `winsor' >= 100 | `winsor' <= 0 {
        display as error "The winsorized value should be in the range of 1 to 99"
        error 198
      } 
      
      quietly {  
        // Winsorized Part
        if (`W_USED' == 1 & inrange(`winsor',0,100)) {
          tempvar counta
          tempvar win_var
          
          *generate winsorized variable (left side only)
          winsor2 `var', suffix(_win) label cuts(`winsor' 100)
          
          * Local count of winsorized observations
          count if `var'_win != `var' & `var' > 0
          local WW = r(N)
          
          *create new var with the same values as _win
          drop `var'
          gen  `var' = `var'_win
          drop `var'_win

        } 
      }
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
      
      
      * MESSAGES
      * ------------------------------------------------------------------------
    
      * Message: general note for each index
      if !missing("`notes'") {
        display as result "W Index is defined as: the factor by which `varlist' should be multiplied to reach z."   
        display as result "C Index is defined as: the average factor by which `varlist' needs to be multiplied to attain the standard of living defined by the threshold, with no increase for people above the threshold z."  
        display as result "P Index is defined as: C - 1 which is the average growth rate needed to attain the standard of livign defined by the threshold z."     
        display as result "I Index is defined as: the inequality index which is the average factor by which `varlist' must be multiplied to get to the mean `varlist'."         
      }     
      
      
      * Message: Count 0 and not bottomcoded
      if (`NN' != 0) & (`BC_USED' == 0 & `W_USED' == 0) {
        display as error "Warning: There are a total of `NN' observations with 0s or negatives in your dataset and they have been removed from the estimations. Please check the distribution of `varlist'."
      }
      
      * Message: Count 0 and not bottom coded and observations with 0s
      else if (`ZZ' != 0) & (`BC_USED' == 0 & `W_USED' == 0) {
        display as error "Warning: There are a total of `NN' observations with 0s or negatives in your dataset and they have been removed from the estimations. Please check the distribution of `varlist'."
      }
      
      * Message: Count 0 and bottom coded
      else if (`NN' != 0) & (`BC_USED' == 1) {
        display as error "Warning: There are a total of `NBC' observations with values less than `bc' in your dataset. `NBC' were bottom coded and have been set to `bc'."
        display as error "There are also `NN' with 0s or negatives in your dataset and they have been removed from the estimations. Please check the distribution of `varlist'."
      }
      
      * Message: Count 0 and bottom coded
      else if (`NN' != 0) & (`BC_USED' == 1) {
        display as error "Warning: There are a total of `NBC' observations with values less than `bc' in your dataset. `NBC' were bottom coded and have been set to `bc'."
        display as error "There are also `NN' with 0s or negatives in your dataset and they have been removed from the estimations. Please check the distribution of `varlist'."
      }
      
      * Message: Count 0 and winsorized variables
      else if (`NN' != 0) & (`W_USED' == 1) {
        display as error "Warning: A total of `WW' observations were left-winsorized at the `winsor' percentile in your dataset."
        display as error "There are also `NN' with 0s or negatives in your dataset and they have been removed from the estimations. Please check the distribution of `varlist'."
      }
      
      * Message: Paper notes
      display as result "Note: These indices correspond to the four welfare, poverty, and inequality indices discussed in Section 2 of Kraay (r) al. (2023)." 
    } 
    
    * Other checks
    else if `z' <= 0 {
      noisily display as error "Negative z is not allowed."
      error 198
    }

    * If dot plot
    if !missing("`dotplot'") {
      twoway scatter `varlist' W, msize(small) ///
        title("Individual contribution (ratio)" "as a function of `lbl'", size(medsmall))
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

    
    
