*! version 0.0.8 06DIC2023 Average Welfare Factor

capture program drop awf
program define awf, rclass
  version 12
  syntax varlist(min=1 max=1) [if] [in],  ///
    z(real)                               ///
    [                                     ///
    NONOTES                               ///
    KEEPvars                              ///
    DOTplot                               ///
    BCN(numlist > 0)                      ///
    BCP(numlist min = 1 max = 99)         ///
    ]
       
  * Remove observations (i.e., excluded by if or in)
  marksample touse, novarlist
  quietly keep if `touse'
    
  * Tempvars
  tempvar var
  tempvar Z         
  tempvar W         
  tempvar censored  
  tempvar C           
  tempvar P         
  tempvar I         
  
  *Local to indicate if bc or winsor are included
  if missing("`bcn'")         local BC_USED = 0
  else if !missing("`bcn'")   local BC_USED = 1
  if missing("`bcp'")         local W_USED  = 0
  else if !missing("`bcp'")   local W_USED  = 1
  
  * Warning    
  if `BC_USED' == 1 & `W_USED' == 1 {
    display in w "bcn() " in red "cannot be specified with" in w " bcp()" 
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
      
  // BCN option
  if `BC_USED' == 1 {
    quietly {
      // Bottom-coded part 
      if (`BC_USED' == 1 & `bcn' > 0) {
        tempvar counta
        
        *create counter of bottom-coded obs
        gen `counta'      = 0
        replace `counta'  = 1 if `var' < `bcn' & !missing(`var')
        
        *replace values in estimating variable
        replace `var'     = `bcn' if `counta' == 1
        
        * local counter of bottom-coded changes
        count if `counta' == 1
        local NBC = r(N)
        
        *we need to also include those that are negative or zeros (so, replace again)
        replace `var'     = `bcn' if `varlist' <= 0 
        
        *total changes
        local TNBC = `NBC' + `NN'
      } 
    }
  }
  
  // BCP option
  if `W_USED' == 1 {
    if `bcp' >= 100 | `bcp' <= 0 {
      display as error "The winsorized value should be in the range of 1 to 99"
      error 198
    } 
    
    quietly {  
      // Getting the percentile part
      if (`W_USED' == 1 & inrange(`bcp',0,100)) {
        tempvar win_var
        
        * Get back the weight information if any
        svyset
        if !missing("`r(wvar)'") {
          local weight_type   = "`r(wvar)'"
          local weight_option = "[w = `weight_type']"
        }
        else {
          local weight_option = ""
        }
        * Gen variables for percentile
        gen `win_var' = `varlist'
        _pctile `win_var' `weight_option', p(`bcp') // For the whole distribution not only for positives
        local percentile = r(r1)
        replace `win_var' = `percentile' if  `win_var' <= `percentile'
        
        * Local count of the weighted percentile observations
        sum `varlist' `weight_option' if `varlist' < `percentile' 
        local WW = r(sum_w)
        
        sum `varlist' `weight_option' if `varlist' <= 0
        local WWNeg = r(sum_w)
        
        *create new var with the same values as _win
        drop `var'
        gen  `var' = `win_var'
        drop `win_var'

      } 
    }
  }
  
  quietly {
    * Generate the variables
    // W Index
    gen `Z'   = `z'    
    gen `W'   = `Z' / `var'       if `var' > 0 & !missing(`var')
    // C Index
    gen `censored'     = `var'    if `var' <  `Z'
    replace `censored' = `Z'      if `var' >= `Z'
    gen `C' = (`Z' / `censored')
    // P Index
    gen `P' = (`Z' / `censored') - 1
    // I Index
    quietly svy: mean `var'
    matrix define mat_mean = r(table)
    local mat_mean = r(table)[1,1]
    gen `I' = `mat_mean' / `var'
  }
    
  * Label varlist
  local lbl : variable label `varlist'
  
  * Check if z is positive
  if `z' > 0 {
    * Mean estimates
    display as text "Distribution-Sensitive Index for var: `varlist'"
    
    capture drop W C P I
    quietly {
      gen W = `W'
      gen C = `C'
      gen P = `P'
      gen I = `I'
    }
    
    svy: mean W C P I `if' `in'
    capture drop W C P I
    
    * ------------------------------------------------------------------------    
    * MESSAGES
    * ------------------------------------------------------------------------
    * Message: general note for each index
    if missing("`nonotes'") {
      display as result `"W: welfare index (please see Equation (1) {browse "https://documents.worldbank.org/en/publication/documents-reports/documentdetail/099934305302318791/idu0325015fc0a4d6046420afe405cb6b6a87b0b":in Kraay et al. 2023})"'   
      display as result `"C: censored welfare index (please see Equation (2) {browse "https://documents.worldbank.org/en/publication/documents-reports/documentdetail/099934305302318791/idu0325015fc0a4d6046420afe405cb6b6a87b0b":in Kraay et al. 2023})"'  
      display as result `"P = C - 1 (please see Equation (3) in {browse "https://documents.worldbank.org/en/publication/documents-reports/documentdetail/099934305302318791/idu0325015fc0a4d6046420afe405cb6b6a87b0b":in Kraay et al. 2023})"'     
      display as result `"I: inequality index (please see Equation (6) {browse "https://documents.worldbank.org/en/publication/documents-reports/documentdetail/099934305302318791/idu0325015fc0a4d6046420afe405cb6b6a87b0b":in Kraay et al. 2023})"'   
      display as result _newline `"Please refer to Section 2 in {browse "https://documents.worldbank.org/en/publication/documents-reports/documentdetail/099934305302318791/idu0325015fc0a4d6046420afe405cb6b6a87b0b":Kraay et al. (2023)} for the properties and interpretation of each of these indices."'
    }     
    
    * If obs with 0s or negatives
    if (`NN' != 0 & `BC_USED' == 0 & `W_USED' == 0) {
        display as error _newline "Warning: There are `NN' observations in your dataset, where {it:`varlist'} <= 0." _newline "These observations have been excluded from the analysis. If you want these observations to be included in the analysis," _newline "you can bottom-code {it:`varlist'} using the bcn (number) or the bcp (percentile) options."    
    }
        
    * If BC used
    if (`BC_USED' == 1) {
      display as error _newline "Warning: There are a total of `TNBC' observations with {it:`varlist'} < 3 in your dataset, including `NN' where `varlist' <= 0, all of which have been bottom coded to set `varlist' = `bcn'"
    }
    
    * If winsorized
    if (`W_USED' == 1) {
      display as error _newline "Warning: There are a total of `WW' observations with {it:`varlist'} < `percentile' in your dataset," _newline "including `WWNeg' where {it:`varlist'} <= 0, all of which have been bottom coded to set {it:`varlist'} = `percentile'." _newline "`percentile' is the (weighted) value of the `bcp'th percentile of the distribution of {it:`varlist'}." _newline "Please make sure you are using the weight option when using BCP to estimate the proper percentile."
    }
  } 
  
  * Other checks
  else if `z' <= 0 {
    noisily display as error "Negative z is not allowed."
    error 198
  }

  * If dot plot
  if !missing("`dotplot'") {
    twoway scatter `varlist' `W', msize(small) ///
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
  if !missing("`keepvars'") {
    capture drop Z W censored C P I
      
    gen Z         = `Z'         
    gen W         = `W'
    gen censored  = `censored'
    gen C         = `C'
    gen P         = `P'
    gen I         = `I'
  
    * Label vars
    label var Z         "Reference Income"
    label var W         "Welfare Index"  
    label var censored  "Censored"
    label var C         "Censored Welfare Index"  
    label var P         "(C - 1)"
    label var I         "Inequality Index"
  } 
  
end

  
  
