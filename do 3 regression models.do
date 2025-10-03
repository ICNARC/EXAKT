/*******************************************************************************
Project: EXAKT
Do file for: regression modelling & preparation for plotting and tabular outputs
*******************************************************************************/

* config
version 17
set varabbrev off
set more off
cap log close
log using "log 3 regression models", replace
di "ExtractDate: $ExtractDate"

* import & reshape data
use EXAKT$ExtractDate, clear
reshape long OXIMETER_ SPO2_OXI, i(Label RepeatNumber) j(oximeter_n)
bysort Label oximeter_n (OXIMETER_): replace OXIMETER_ = OXIMETER_[_N]
encode OXIMETER_ if !inlist(OXIMETER_,"-1","-2","-3"), gen(o)
lab var o "Pulse oximeter model"

* transorm saturation %s to fractions
g spfrac = SPO2_OXI/100
lab var spfrac "SpO2 fraction"
g safrac = round(SAO2_PDC,1)/100
lab var safrac "SaO2 fraction"

* clean HB and cap at 1st and 99th pctiles
replace HB = . if HB <0
sum HB, detail
replace HB = r(p1) if HB < r(p1)
replace HB = r(p99) if HB > r(p99) & !mi(HB)

* encode patient pseudoidentifer
sort Label
generate byte pid=1 if _n==1
replace pid=pid[_n-1] + (Label!=Label[_n-1]) if _n > 1

* derive splines for ITA, SaO2 and HB					
mkspline t = ITA, cubic nk(4)
mat tk = r(knots) //store knot positions for graphing
mkspline s = safrac, cubic nk(4) 
mat sk = r(knots) //store knot positions for graphing
mkspline h = HB, cubic nk(4)
mat hk = r(knots) //store knot positions for graphing
	
* SpO2/bias model: fractional regression with patient-clustered vce
fracreg probit spfrac t? s? c.t1#c.s1 c.t1#c.s2 c.t1#c.s3 c.t2#c.s1 c.t3#c.s1 ///
	i.o i.o#c.t1 i.o#c.t2 i.o#c.t3 i.o#c.s1 i.o#c.s2 i.o#c.s3 ///
	h?	///
	, vce(cluster pid)
estimates store fracreg
estimates save fracreg, replace

* Precision model (squared deviation SpO2 - SpO2fit)
estimates use fracreg
predict sp_pr_overall
g SquaredDeviation = (spfrac - sp_pr_overall)^2
lab var SquaredDeviation "Square of (spfrac - sp_pr)"
fracreg probit SquaredDeviation t? s? c.t1#c.s1 c.t1#c.s2 c.t1#c.s3 c.t2#c.s1 c.t3#c.s1 ///
	i.o i.o#c.t1 i.o#c.t2 i.o#c.t3 i.o#c.s1 i.o#c.s2 i.o#c.s3 ///
	h?	///
	, vce(cluster pid)
estimates store precision
estimates save precision, replace

* ARMS model (squared error SpO2 - SaO2)
g SquaredError = (spfrac-safrac)^2
lab var SquaredError "squared error"
fracreg probit SquaredError t? s? c.t1#c.s1 c.t1#c.s2 c.t1#c.s3 c.t2#c.s1 c.t3#c.s1 ///
	i.o i.o#c.t1 i.o#c.t2 i.o#c.t3 i.o#c.s1 i.o#c.s2 i.o#c.s3 ///
	h?	/// 
	, vce(cluster pid)
estimates store mse
estimates save mse, replace

* ROC regression for prediction of saO2 <= 92 (AUROC model)
	* generate outcome variable
	g sa92orless = safrac <= float(0.92)
	lab var sa92orless "SaO2 < 92"
	
	* generate oximeter dummies and interactions (factor variables not accepted by rocreg)
	tabulate o, gen(o)

	forval o= 1/5{
		forval t = 1/3{
			g o`o't`t' = cond(o==`o',t`t',0)
			lab var o`o't`t' "Oximeter `=char(`o' + 64)' interaction with ITA spline `t'"
		}
	}
	
	* reverse spfrac because SpO2 is inversely associated with likelihood of hypoxaemia (otherwise AUROC scales towards 0 instead of 1)
	g spfrac_reverse = 1 - spfrac 
	lab var spfrac_reverse "1 - SpO2"
	
	* fit model (NB to allow covariates affectin the ROC, the model must be fitted using Maximum Likelihood)
	rocreg sa92orless spfrac_reverse, probit ml cluster(pid) ctrlcov(h?) /// 
		roccov(o2 o3 o4 o5 t1 t2 t3 ///
			o2t1 o3t1 o4t1 o5t1 ///
			o2t2 o3t2 o4t2 o5t2 ///
			o2t3 o3t3 o4t3 o5t3) //
	estimates store rocreg
	estimates save rocreg, replace

* Sensitivity and Specificity models (probabilitys of SpO2<X given case/non-case)
foreach i in 92 94{
	g byte sp`i'orless = spfrac<=float(0.`i') if !mi(spfrac)
	melogit sp`i'orless t? s? c.t1#c.s1 c.t1#c.s2 c.t1#c.s3 c.t2#c.s1 c.t3#c.s1 ///
		i.o i.o#c.t1 i.o#c.t2 i.o#c.t3 i.o#c.s1 i.o#c.s2 i.o#c.s3 ///
		h?	///
		|| SiteNumber: || pid: // sample too small to include RepeatNumber?
	estimates store sp`i'orless
	estimates save sp`i'orless, replace
}

save EXAKT${ExtractDate}_postregression, replace

log close	


