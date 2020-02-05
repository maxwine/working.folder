// Assignment #1
// Max Wang
// YW2636
// Feb, 2020

cd "/Users/yw2636/Google Drive/Spring2020/method/term2/HW1"

* Read in data: 
insheet using "working.folder/assignment1-research-methods.csv", tab names clear

* Label your variables
label variable candidateid "ID"
label variable calledback "Callback"
label variable recruiteriswhite "Recruiter is white"
label variable recruiterismale "Recruiter is male"

sort candidateid

* Some summary stats
codebook candidateid
tab calledback
tab recruiteriswhite 
tab recruiterismale 
pwcorr calledback recruiteriswhite recruiterismale malecandidate ///
	eliteschoolcandidate bigcompanycandidate, star(.05)
	
/* Summary:
at 5% level, only elite school and big company candidates are correlated with
callbacks.
*/	

* Run regression: 
est clear

** univariate
qui reg calledback 1.eliteschoolcandidate 
eststo ols1

qui logit calledback 1.eliteschoolcandidate 
eststo git1

** bivariate with correlated input vars
qui reg calledback 1.eliteschoolcandidate 1.bigcompanycandidate
eststo ols2

qui logit calledback 1.eliteschoolcandidate 1.bigcompanycandidate
eststo git2

** multivariate
qui reg calledback 1.eliteschoolcandidate 1.bigcompanycandidate recruiterismale ///
	recruiteriswhite malecandidate
eststo ols3

qui logit calledback 1.eliteschoolcandidate 1.bigcompanycandidate recruiterismale ///
	recruiteriswhite malecandidate
eststo git3

** multivariate with interactions
qui reg calledback i.eliteschoolcandidate##i.bigcompanycandidate ///
	recruiterismale recruiteriswhite malecandidate
eststo ols4

qui logit calledback i.eliteschoolcandidate##i.bigcompanycandidate ///
	recruiterismale recruiteriswhite malecandidate
eststo git4

** multivariate with interactions robust se
qui reg calledback i.eliteschoolcandidate##i.bigcompanycandidate ///
	recruiterismale recruiteriswhite malecandidate, ///
	cluster(candidateid)
eststo ols5

qui logit calledback i.eliteschoolcandidate##i.bigcompanycandidate ///
	recruiterismale recruiteriswhite malecandidate, ///
	vce(cluster candidateid)
eststo git5

esttab ols* git*, star(* .10 ** .05 *** .01)

/* Summary
1. an applicant from an elite school has higher callback rate.
2. this effect is robust (still positive) but offset (decreasing in magnitude) 
	if the applicant worked at big firms. 
3. the interaction in (2) disappears if we allow recruiters to be heteroskedasitic. 
*/	


**********************************
* LaTex table 
* NOTE!!! - need to call "\usepackage{rotating}"
esttab ols* git* using "working.folder/assignment1-research-methods.tex", ///
	replace eqlabels(none) se label nonumbers r2 star(* .10 ** .05 *** .01) ///
	mtitle("OLS" "OLS" "OLS" "OLS" "\shortstack{OLS\\ClusteredSE}" ///
		"Logit" "Logit" "Logit" "Logit" "\shortstack{Logit\\ClusteredSE}") ///
	title("The Effect of Elite School Training on Interview Callback Rate"\label{tab1}) ///
	interaction(" X ") style(tex) noisily nobaselevels ///
	substitute({table} {sidewaystable}) ///
	bf(%15.2gc) sfmt(%15.2gc) varlabels(_cons Constant, end("" ) nolast) ///
	keep(1.eliteschoolcandidate 1.bigcompanycandidate ///
		1.eliteschoolcandidate#1.bigcompanycandidate recruiterismale ///
		recruiteriswhite malecandidate)


	 
	 



