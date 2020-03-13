* Method HW4
* Max Wang
* Mar 2020

clear all

set more off

cd "~/Google Drive/Spring2020/method/term2/HW4"

insheet using "crime-iv.csv", clear n

global balanceopts "prehead(\begin{tabular}{l*{4}{c}}) postfoot(\end{tabular}) noisily noeqlines nonumbers varlabels(_cons Constant, end("" ) nolast)  starlevels(* 0.1 ** 0.05 *** 0.01)"

global monoton "prehead(\begin{tabular}{l*{4}{c}}) postfoot(\end{tabular}) noisily noeqlines nonumbers varlabels(_cons Constant, end("" ) nolast)  starlevels(* 0.1 ** 0.05 *** 0.01)"


* balance table
est clear

eststo control: qui estpost summarize ///
    severityofcrime monthsinjail recidivates if rep == 0
eststo treated: qui estpost summarize ///
    severityofcrime monthsinjail recidivates if rep == 1
eststo diff: qui estpost ttest ///
	severityofcrime monthsinjail recidivates, by(rep)
	
esttab control treated diff using test.tex, replace ///
	cells("mean(pattern(1 0 0) fmt(2)) mean(pattern(0 1 0) fmt(2)) b(star pattern(0 0 1) fmt(2)) t(pattern(0 0 1) par fmt(2))") ///
	label noobs $balanceopts ///
	collabels("Control" "Treatment" "Difference" "t") 
	
* 1st stage
eststo e1: reg monthsinjail 1.republicanjudge severityofcrime, robust
mat coef = e(b)
g first = _b[1.republicanjudge]

eststo e2: reghdfe monthsinjail 1.republicanjudge, a(severityofcrime) vce(robust)

esttab e*, r2

esttab e* using "hw4_1.tex", ///
	replace eqlabels(none) se label ar2 star(* .10 ** .05 *** .01) ///
	mtitle("First.Stage" "First.Stage-FE") ///
	title("First stage regression of recidivism on jail time and judge party."\label{tab1}) ///
	interaction(" X ") style(tex) noisily nobaselevels ///
	bf(%15.2gc) sfmt(%15.2gc) varlabels(_cons Constant, end("" ) nolast) ///
	keep(1.republicanjudge severityofcrime) ///
	note("Robust standard error in parentheses.")

	
* 1st stage intepretaton
qui eststo discrete_severity: reg monthsinjail 1.republicanjudge severityofcrime

qui eststo categorical_severity: reg monthsinjail 1.republicanjudge i.severityofcrime

suest discrete_severity categorical_severity, vce(robust)

test [discrete_severity_mean]1.republicanjudge = [categorical_severity_mean]1.republicanjudge

* 2nd stage 
eststo e3: reg recidivates 1.republicanjudge severityofcrime, robust
mat coef = e(b)
g second = _b[1.republicanjudge]

esttab e*, r2

* 2sls coeff
di second/first

* use package ivreg2
eststo e4: ivreg2 recidivates (monthsinjail=1.republicanjudge) severityofcrime, robust

esttab e1 e3 e4, r2

esttab e1 e3 e4 using "hw4_2.tex", ///
	replace eqlabels(none) se label star(* .10 ** .05 *** .01) ///
	mtitle("First.Stage" "Second.Stage" "IV") ///
	title("IV regression of recidivism on jail time and judge party."\label{tab1}) ///
	interaction(" X ") style(tex) noisily nobaselevels ///
	bf(%15.2gc) sfmt(%15.2gc) varlabels(_cons Constant, end("" ) nolast) ///
	keep(1.republicanjudge monthsinjail) ///
	note("Robust standard error in parentheses.") scalar(F)


* monotonicity 
eststo s1: estpost ttest monthsinjail if severityofcrime == 1,  by(rep) welch
eststo s2: estpost ttest monthsinjail if severityofcrime == 2,  by(rep) welch
eststo s3: estpost ttest monthsinjail if severityofcrime == 3,  by(rep) welch

esttab s1 s2 s3 using monotonicity.tex, replace ///
	cells("b(star pattern(1 0 0) fmt(2)) b(star pattern(0 1 0) fmt(2)) b(star pattern(0 0 1) fmt(2))") ///
	label noobs $balanceopts ///
	collabels("Severity.1" "Severity.2" "Severity.3" "t") 
	
tw (hist monthsinjail if monthsinjail!=0 & severityofcrime==1 & rep==0, bin(20) fcolor(navy*0.8)) ///
	(hist monthsinjail if monthsinjail!=0 & severityofcrime==1 & rep==1, bin(20) fcolor(maroon*0.8)), ///
	graphregion(color(white)) xsize(20) ysize(12) ///
	yti("Density", size(*.8)) ylab(none) xti("") ///
	subti("Severity of crime = 1", size(small)) ///
	legend(off)
gr save "temp1.gph", replace
	
tw (hist monthsinjail if monthsinjail!=0 & severityofcrime==2 & rep==0, bin(30) fcolor(navy*0.8)) ///
	(hist monthsinjail if monthsinjail!=0 & severityofcrime==2 & rep==1, bin(50) fcolor(maroon*0.8)), ///
	graphregion(color(white)) xsize(20) ysize(12) ///
	yti("Density", size(*.8)) ylab(none) xti("") ///
	subti("Severity of crime = 2", size(small)) ///
	legend(off)
gr save "temp2.gph", replace

tw (hist monthsinjail if monthsinjail!=0 & severityofcrime==3 & rep==0, bin(50) fcolor(navy*0.8)) ///
	(hist monthsinjail if monthsinjail!=0 & severityofcrime==3 & rep==1, bin(50) fcolor(maroon*0.8)), ///
	graphregion(color(white)) xsize(20) ysize(12) ///
	yti("Density", size(*.8)) ylab(none) xti("") ///
	subti("Severity of crime = 3", size(small)) ///
	legend(order(1 "Democrats" 2 "Republicans") row(1) pos(12) size(*.5))
gr save "temp3.gph", replace

grc1leg "temp1.gph" "temp2.gph" "temp3.gph", xcommon legendfrom("temp3.gph") ///
	graphregion(color(white)) xsize(16) ysize(20) row(3) ///
	ti("Cross-severity check - distribution of jail time by judges from different political parties", size(small)) ///
	pos(12) 
gr export "p2.png", replace

* compliers only regression
eststo e5: ivreg2 recidivates (monthsinjail=1.republicanjudge) if severityofcrime==2, robust

esttab e1 e3 e4 e5, r2

esttab e1 e3 e4 e5 using "hw4_3.tex", ///
	replace eqlabels(none) se label star(* .10 ** .05 *** .01) ///
	mtitle("First.Stage" "Second.Stage" "IV" "IV-LATE") ///
	title("IV regression of recidivism on jail time and judge party."\label{tab1}) ///
	interaction(" X ") style(tex) noisily nobaselevels ///
	bf(%15.2gc) sfmt(%15.2gc) varlabels(_cons Constant, end("" ) nolast) ///
	keep(1.republicanjudge monthsinjail) ///
	note("Robust standard error in parentheses.") scalar(F)
