{smcl}
{* 20 May 2023}{...}
{hline}
help for {hi:senindex}
{hline}

{title:Title}

{phang2}{cmdab:senindex} {hline 2} Calculate distribution-sensitive indices

{title:Syntax}

{phang2}
{cmdab:senindex} {it:varlist(min=1 max=1)} [{help if:if}] [{help in:in}] [{help weight}], {cmdab:z()}{it:real}{cmd:)} 
[
{cmdab:dot:plot}
{cmdab:keep:vars}
{cmdab:nonotes}
]

{marker opts}{...}
{synoptset 23}{...}
{synopthdr:options}
{synoptline}
{pstd}{it:    {ul:{hi:Required options:}}}{p_end}

{synopt :{cmdab:z(}{it:real}{cmd:)}}Specifies the reference income value for calculating the indices. It must be a positive real number..{p_end}

{pstd}{it:    {ul:{hi:Optional options}}}{p_end}

{synopt :{cmdab:dot:plot}}Displays a dot plot of the individual contribution as a ratio of the specified variable.{p_end}
{synopt :{cmdab:keep:vars}}Keeps the generated variables after executing the command.{p_end}
{synopt :{cmdab:nonotes}}Suppresses the display of additional notes about the indices.{p_end}

{synoptline}

{title:Description}

{pstd}{cmdab:sendindex}: The senindex command calculates distribution-sensitive indices based on a specified variable. It provides four indices: W Index, C Index, P Index, and I Index. The indices are calculated using the reference income specified by the 'z' option.

{title:Remarks}
- The senindex command calculates four distribution-sensitive indices:
    1. W Index: Represents the factor by which the specified variable should be multiplied to reach the reference income (z).
    2. C Index: Represents the average factor by which the specified variable needs to be multiplied to attain the standard of living defined by the threshold (z), with no increase for people above the threshold.
    3. P Index: Represents the average growth rate needed to attain the standard of living defined by the threshold (z), calculated as C - 1.
    4. I Index: Represents the inequality index, which is the average factor by which the specified variable must be multiplied to reach the mean of the variable.

- If the specified variable contains zero or negative values, they are set to the smallest positive value by default.

- The senindex command supports the use of survey data with the svy prefix. Make sure to set the appropriate survey design using svyset before running the command.

{title:Examples}
1. Calculate the distribution-sensitive indices using the variable "income" with a reference income of 1000:
    . senindex income, z(1000)

2. Calculate the indices using survey data and weights:
    . webuse stage5a_jkw, clear
    . 
    . * set dummy svyset and generate income
    . svyset [pweight=pw], jkrweight(jkw_*) vce(jackknife)
    . gen income = runiformint(1,10000)
    .
    . * index
    . senindex income, z(2000) keep nonotes

{title:Author}

{phang}Author: The World Bank Group

