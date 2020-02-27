* HW3
* MAX WANG

clear all

cd "~/Google Drive/Spring2020/method/term2/HW3"

insheet using sports-and-education.csv, clear

global balanceopts "prehead(\begin{tabular}{l*{6}{c}}) postfoot(\end{tabular}) noisily noeqlines nonumbers varlabels(_cons Constant, end("" ) nolast)  starlevels(* 0.1 ** 0.05 *** 0.01)"

* Q2.1. test homogenous variance
sdtest academicquality, by(ranked2017)
sdtest athleticquality, by(ranked2017) 
sdtest nearbigmarket, by(ranked2017)


* 2.2. t test 
est clear

eststo control: qui estpost summarize ///
    academicquality athleticquality nearbigmarket if ranked2017 == 0
eststo treated: qui estpost summarize ///
    academicquality athleticquality nearbigmarket if ranked2017 == 1
eststo diff: qui estpost ttest ///
	academicquality athleticquality nearbigmarket, by(ranked2017)

esttab control treated diff using test.tex, replace ///
	cells("mean(pattern(1 0 0) fmt(2)) mean(pattern(0 1 0) fmt(2)) b(star pattern(0 0 1) fmt(2)) t(pattern(0 0 1) par fmt(2))") ///
	label noobs $balanceopts ///
	collabels("Control" "Treatment" "Difference" "t") 
	
* Q4. build propensity score
qui logit ranked2017 academicquality athleticquality nearbigmarket, robust
predict p_score, pr 
tw (scatter ranked2017 p_score) (function invlogit(x), ra(-10 10) xaxis(2) yaxis(2)), ///
	xlab(none, axis(2)) ylab(none, axis(2)) xti("", axis(2)) yti("", axis(2)) ///
	legend(off) graphregion(color(white)) ///
	yti("Actual assignment") xti("Propensity score") ///
	ti("Propensity score using Logit prediction")
gr export "p1.png", replace

* Q5. overlap
tw (kdensity p_score if ranked2017 == 0, bw(.25)) ///
	(kdensity p_score if ranked2017 == 1, bw(.25)), ///
	xti("Score") yti("Density") ti("Propensity score overlap") ///
	legend(order(1 "Control" 2 "Treated"))  graphregion(color(white))
gr export "p2.png", replace
g has_overlap = (inrange(p_score, .2, .8))

* Q6. reassignment
keep if has_ == 1
sort p_score
gen block = floor((_n-.1)/4)
bys block: g order = _n
save "tempdata.dta", replace

* Q6. reassignment
u tempdata.dta, clear
g treatment = (order == 1 | order == 2)

est clear

qui reg alumnidonations2018 1.treatment, robust
eststo est1

qui reg alumnidonations2018 1.treatment academicquality athleticquality 1.nearbigmarket, robust
eststo est2

qui areg alumnidonations2018 1.treatment academicquality athleticquality 1.nearbigmarket, a(block) robust
eststo est3

g TreatedXAcademic = 1.treatment#academicquality
g TreatedXAthletic = 1.treatment#athleticquality
g TreatedXMetro = 1.treatment#1.nearbigmarket

qui areg alumnidonations2018 1.treatment academicquality athleticquality 1.nearbigmarket TreatedX*, a(block) robust
eststo est4

esttab est* using "hw3_1.tex", ///
	replace eqlabels(none) se label ar2 star(* .10 ** .05 *** .01) ///
	mtitle("Baseline" "Basedline" "Block-FE" "Blcok-FE") ///
	title("Treatement Effects of Ranking on University Alumni Donation"\label{tab1}) ///
	interaction(" X ") style(tex) noisily nobaselevels ///
	bf(%15.2gc) sfmt(%15.2gc) varlabels(_cons Constant, end("" ) nolast) ///
	keep(1.treatment 1.nearbigmarket academicquality athleticquality TreatedX*) 

drop treatment TreatedX*
g treatment = (order == 2 | order == 3)
est clear

qui reg alumnidonations2018 1.treatment, robust
eststo est1

qui reg alumnidonations2018 1.treatment academicquality athleticquality 1.nearbigmarket, robust
eststo est2

qui areg alumnidonations2018 1.treatment academicquality athleticquality 1.nearbigmarket, a(block) robust
eststo est3

g TreatedXAcademic = 1.treatment#academicquality
g TreatedXAthletic = 1.treatment#athleticquality
g TreatedXMetro = 1.treatment#1.nearbigmarket

qui areg alumnidonations2018 1.treatment academicquality athleticquality 1.nearbigmarket TreatedX*, a(block) robust
eststo est4

esttab est* using "hw3_2.tex", ///
	replace eqlabels(none) se label ar2 star(* .10 ** .05 *** .01) ///
	mtitle("Baseline" "Basedline" "Block-FE" "Blcok-FE") ///
	title("Treatement Effects of Ranking on University Alumni Donation, 2nd Assignment"\label{tab1}) ///
	interaction(" X ") style(tex) noisily nobaselevels ///
	bf(%15.2gc) sfmt(%15.2gc) varlabels(_cons Constant, end("" ) nolast) ///
	keep(1.treatment 1.nearbigmarket academicquality athleticquality TreatedX*) 


