
* SETUP
clear 
set obs 1000
svyset, srs
capture drop w1
gen w1 = _n

* Get weights
capture drop wt1
gen wt1 = 1
replace wt1 = 10 if w1>500.5
capture drop wt2
gen wt2 = 10
replace wt2 = 1  if w1>500.5

* Testing with only z and weights 
svyset [w=wt1]
awf w1, z(500.5)
awf w1, z(705.0455)

* Testing with only z and no weights 
svyset, srs
gen     w2 = w1
replace w2 = 500.5 if w1 > 500.5
awf w1, z(500.5)
awf w2, z(500.5)

svyset [w=wt1]
awf w1, z(500.5)
awf w2, z(500.5)

* Testing with BC option
gen w3 = w1-15
awf w1, z(300)                  // All positives = 1000
awf w3, z(300)                  // 15 <= 0 //  985
awf w3, z(300) bcn(3)           // BC 17: 15 <= 0, total = 1000

* Testing with BCP option
svyset,srs 
awf w3, z(300) bcp(3)
svyset [w=wt1]     
awf w3, z(300) bcp(3)           


