{smcl}
{* 31 May 2023}{...}
{hline}
help for {hi:awf}
{hline}

{title:Title}

{phang}{cmdab:awf} {hline 2} Calculate distribution-sensitive welfare indices

{title:Syntax}

{phang}
{cmdab:awf} {it:varlist(min=1 max=1)} [{help if:if}] [{help in:in}] [{help weight}], {cmdab:z(}{it:real}{cmd:)} 
[
{cmdab:keep:vars}  
{cmdab:dot:plot}
{cmdab:nonotes}
{cmdab:bcn(}{it:num)} 
{cmdab:bcp(}{it:num} {cmdab:min=1 max=99)} 
]

{marker opts}{...}
{synoptset 23}{...}
{synopthdr:options}
{synoptline}
{pstd}{it:    {ul:{hi:Required:}}}{p_end}

{synopt :{cmdab:varlist}}Specifies the variable identifying individual level welfare (e.g., consumption, income, wealth). For clarity, the help file uses the specific example of income when referring to this variable.{p_end}
{synopt :{cmdab:z(}{it:real}{cmd:)}}Specifies the threshold reference value of income used income value for calculating the indices. It must be a positive real number.{p_end}

{pstd}{it:    {ul:{hi:Optional options}}}{p_end}

{synopt :{cmdab:keep:vars}}Keeps the generated variables after executing the command.{p_end}
{synopt :{cmdab:nonotes}}Supresss notes regarding the indices.{p_end}
{synopt :{cmdab:bcn(}{it:real}{cmd:)}}Specifies the value for bottom coding income. All observations with values lower than bc are recoded as bc. If bc is not specified, zeros and negative values are dropped from the analysis.{p_end}
{synopt :{cmdab:bcp(}{it:real}{cmd:)}}Specifies the percentile for bottom coding income. All observations with values lower than bcp are recoded as bcp. If bcp is not specified, zeros and negative values are dropped from the analysis.{p_end}
{synopt :{cmdab:dot:plot}}Displays a dot plot of the individual contribution as a ratio of the specified variable.{p_end}

{synoptline}

{title:Description}

{pstd}{cmdab:awf}: The {cmdab:awf} command calculates distribution-sensitive indices defined in {browse "https://documents.worldbank.org/en/publication/documents-reports/documentdetail/099934305302318791/idu0325015fc0a4d6046420afe405cb6b6a87b0b":Kraay et al. (2023)} based on the specified income variable and the threshold value 'z' of income. 
It provides four indices: W Index, C Index, P Index, and I Index. To use {cmdab:awf}, the user must set up the data with the {cmdab:svyset} command. In those cases where the user wants to treat the data as if it were drawn from the simple random sample, then consider using {cmdab:svyset, srs}. 


{title:Remarks}
- The {cmdab:awf} command calculates four distribution-sensitive indices:
    1. W Index: Represents the average value of the factor by which each person’s (or observation) income is multiplied to reach the threshold income value of (z).
    2. C Index: This measure is W on a transformed value of income. Specifically, the income vector is censored (i.e., top-coded) at the threshold income value. 
    In this case, the factor by which each person’s income is multiplied to reach z takes the value of 1 for all people with income greater than or equal to z. 
    3. P Index: Represents the average growth rate needed to attain the standard of living defined by the threshold (z), calculated as C - 1.
    4. I Index: Represents the inequality index, which is the average factor by which income must be multiplied to reach the mean of income.

- The {cmdab:awf} command supports the use of survey data with the svy prefix. Make sure to set the appropriate survey design using svyset before running the command.

{title:Examples}
1. Calculate the distribution-sensitive indices using the variable "income" with a reference income of 1000:
    . awf income, z(1000)

2. Calculate the indices using survey data and weights:
    . webuse stage5a_jkw, clear
    . 
    . * set dummy svyset and generate income
    . svyset [pweight=pw], jkrweight(jkw_*) vce(jackknife)
    . gen income = runiformint(1,10000)
    .
    . * index
    . awf income, z(2000) keep nonotes

{title:Authors}

{phang} Rony Rodriguez Ramirez, Development Research Group, The World Bank - Harvard University

{phang} Dean Mitchell Jolliffe, Development Data Group, The World Bank

{phang} Berk Ozler, Development Research Group, The World Bank




