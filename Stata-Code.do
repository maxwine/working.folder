// Assignment #2
// Max Wang
// YW2636
// Feb, 2020


// PART I.

cd "/Users/yw2636/Google Drive/Spring2020/method/term2/HW2"

* Read in data: 
insheet using "assignment1-research-methods.csv", tab names clear

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

** baseline model
qui reg calledback 1.eliteschoolcandidate 1.bigcompanycandidate recruiteriswhite recruiterismale
margins, dydx(eliteschoolcandidate bigcompanycandidate) post
eststo ols1

qui logit calledback 1.eliteschoolcandidate 1.bigcompanycandidate recruiteriswhite recruiterismale
margins, dydx(eliteschoolcandidate bigcompanycandidate) post
eststo git1

** male candidate
qui reg calledback 1.eliteschoolcandidate 1.bigcompanycandidate 1.malecandidate recruiteriswhite recruiterismale
margins, dydx(eliteschoolcandidate bigcompanycandidate malecandidate) post
eststo ols2

qui logit calledback 1.eliteschoolcandidate 1.bigcompanycandidate 1.malecandidate recruiteriswhite recruiterismale
margins, dydx(eliteschoolcandidate bigcompanycandidate malecandidate) post
eststo git2

** male candidate plus more controls plus clustered std err
g EliteXBigCompany = 1.eliteschoolcandidate#1.bigcompanycandidate
qui reg calledback 1.eliteschoolcandidate 1.bigcompanycandidate EliteXBigCompany 1.malecandidate ///
	recruiteriswhite recruiterismale, cluster(candidateid)
margins, dydx(eliteschoolcandidate bigcompanycandidate EliteXBigCompany malecandidate) post
eststo ols3

qui logit calledback 1.eliteschoolcandidate 1.bigcompanycandidate EliteXBigCompany 1.malecandidate ///
	recruiteriswhite recruiterismale, vce(cluster candidateid)
margins, dydx(eliteschoolcandidate bigcompanycandidate EliteXBigCompany malecandidate) post
eststo git3

label var eliteschoolcandidate "EliteSch"
label var bigcompanycandidate "BigComp"
label var malecandidate "MaleApp"
label var EliteXBigCompany "EliteSchXBigComp"

esttab ols* git* using "hw2_1.tex", ///
	replace eqlabels(none) se label star(* .10 ** .05 *** .01) ///
	mtitle("OLS" "OLS" "\shortstack{OLS\\ClusteredSE}" ///
		"Logit" "Logit" "\shortstack{Logit\\ClusteredSE}") ///
	title("Marginal Effects of Elite Schoole, Bigfirm and Male Candidacy on Interview Callback Rate"\label{tab1}) ///
	interaction(" X ") style(tex) noisily nobaselevels ///
	bf(%15.2gc) sfmt(%15.2gc) varlabels(_cons Constant, end("" ) nolast) ///
	keep(1.eliteschoolcandidate 1.bigcompanycandidate EliteXBigCompany 1.malecandidate) ///
	note("Note: additional controls include recruiters' gender and race.")


// PART II
insheet using "vaping-ban-panel.csv", names clear

* first, distributions 
g l_lunghospitalizations = ln(lunghospitalizations)
g hos = lunghospitalizations/1000
tw (hist hos) (kdensity l_lunghospitalizations, xaxis(2) yaxis(2) col("maroon") lw(*2)) ///
	(kdensity l_lunghospitalizations if vapingban==1, xaxis(2) yaxis(2) col("navy")) ///
	(kdensity l_lunghospitalizations if vapingban==0, xaxis(2) yaxis(2) col("green") lp("dash")), ///
	graphregion(color(white)) xsize(20) ysize(12) ///
	xti("n of hospitalizations \ 1000") xti("n of hospitalizations in log", axis(2)) ///
	yti("density") yti("density", axis(2)) yla(, nolabels) yla(, nolabels axis(2)) ///
	legend(order(1 "all hospitalizations" 2 "log all hospitalizations" 3 "treated" 4 "control") ///
	position(12) size(small) row(1)) ylab(, angle(horizontal)) ///
	ti("Distribution of the number of hospitalizations")
gr export "p1.png", replace

/* 
	given the distribution of hospitalizations (bimodal), I think it should be
	okay to just use the `lunghospitalizations'
*/

* regressions
est clear 

reg lunghospitalizations vapingban, robust
eststo est1

reghdfe lunghospitalizations vapingban, a(stateid) vce(robust)
eststo est2

reghdfe lunghospitalizations vapingban, a(stateid year) vce(robust)
eststo est3

reghdfe lunghospitalizations vapingban year, a(stateid) vce(robust)
eststo est4

esttab est*, ar2

* table
esttab est* using "hw2_2.tex", ///
	replace eqlabels(none) ar2 se label star(* .10 ** .05 *** .01) ///
	mtitle("RE" "\shortstack{State\\FE}" ///
		"\shortstack{State-Year\\FE}" "\shortstack{State\\FE}" ) ///
	title("Diff-in-Diff Estimation of the Effect of Vaping Bans"\label{tab1}) ///
	interaction(" X ") style(tex) noisily nobaselevels ///
	bf(%15.2gc) sfmt(%15.2gc) varlabels(_cons Constant, end("" ) nolast) ///
	keep(vapingban year _cons) ///
	note("Note: robust standard errors in parantheses; state FEs are controlled in model (2)-(4).")

* plot
sort year stateid 
bys stateid: egen has_ban = max(vapingban)
tw (lpoly hos year if has_ban==1, deg(1) col("maroon")) ///
	(lpoly hos year if has_ban==0, deg(1) col("navy")), ///
	ti("Treatement effect of vaping ban") ///
	subti("Local polynomial smoothing of degree 1.") ///
	graphregion(color(white)) xsize(20) ysize(12) ///
	yti("n of hospitalizations \ 1000") xti("year") ///
	ylab(, angle(horizontal)) ///
	legend(order(1 "treated states" 2 "control states") position(12))
gr export "p2.png", replace


