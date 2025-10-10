/*******************************************************************************
Project: EXAKT
Do file for: Adjusted AUROC
*******************************************************************************/

* config

version 17
set varabbrev off
set more off
set seed 34261112

* import data
use EXAKT${ExtractDate}_postregression, clear
recode skincat (6=5)

* model overall pulse oximeters (skin tone as continuous covariate)
rocreg sa92orless spfrac_reverse, probit ml cluster(pid) roccov(t?) ctrlcov(h?) //NB to allow covariates affectin the ROC, the model must be fitted using Maximum Likelihood
estimates store rocreg_sk

* model overall skin tones (pulse oximeter as categorical covariate)
rocreg sa92orless spfrac_reverse, probit ml cluster(pid) roccov(o?) ctrlcov(h?) //NB to allow covariates affectin the ROC, the model must be fitted using Maximum Likelihood
estimates store rocreg_ox

* model overall on both
rocreg sa92orless spfrac_reverse, probit ml cluster(pid) ctrlcov(h?) //NB to allow covariates affectin the ROC, the model must be fitted using Maximum Likelihood
matrix overall = r(table) // Store results for overall 

* recreate ITA & SaO2 knot matrix (needed unless do 3 is run first, in same stata session)
mkspline temp = ITA, cubic nk(4) 
mat tk = r(knots)
drop temp?

*store median HB values
preserve
	collapse (median) h?
	g byte n = 1
	tempfile HB
	save `HB'
restore

summ ITA if ITA > -89, detail //excludes one outlier
local min = r(min)
local max = r(max)

* store median l-a-b & RGB values for each level of ITA, for use in visual axis
keep if RepeatNumber==1 & oximeter_n==1
collapse (median) t?, by(skincat)

* add HB
g byte n = 1
merge m:1 n using `HB', nogen

* expand to include 5 oximeters
replace n = _n
expand 5
bysort n: g long o = _n
lab val o o

* generate oximeter dummies and interactions (factor variables not accepted by rocreg)
tabulate o, gen(o)

forval o= 1/5{
	forval t = 1/3{
		g o`o't`t' = cond(o==`o',t`t',0)
		lab var o`o't`t' "Oximeter `=char(`o' + 64)' interaction with ITA spline `t'"
	}
}

*predict each model results over our cohort
estimates use rocreg 
predict auc, auc ci(auc)

estimates restore rocreg_sk
predict auc_sk, auc ci(auc_sk)

estimates restore rocreg_ox
predict auc_ox, auc ci(auc_ox)


** Loop over all to output results by skintone and ox both together and separately
putexcel set "${OutputDir}\\Diagnostic accuracy - AUROC", modify sheet("Adjusted")	
excel
forval i = 1/5{
	* main model
	di "***********  Skin tone: `i' ****************"
	local j = 7 - `i'
	forval o = 1/5{
		summ auc   if o == `o' & skincat == `i'
		local est = trim(string(r(mean),"%4.2f"))
		summ  auc_l  if o == `o' & skincat == `i'
		local lb = trim(string(r(mean),"%4.2f"))
		summ  auc_u if o == `o' & skincat == `i'
		local ub = trim(string(r(mean),"%4.2f"))
		if `o' == 1 {
			putexcel B`j' = ("`est' (`lb', `ub')")
		}
		if `o' == 2 {
			putexcel C`j' = ("`est' (`lb', `ub')")
		}
		if `o' == 3 {
			putexcel D`j' = ("`est' (`lb', `ub')")
		}
		if `o' == 4 {
			putexcel E`j' = ("`est' (`lb', `ub')")
		}
		if `o' == 5 {
			putexcel F`j' = ("`est' (`lb', `ub')")
		}
	}
	
	* overall pulse oximeters
	summ auc_sk   if skincat == `i'
	local est = trim(string(r(mean),"%4.2f"))
	summ  auc_sk_l  if skincat == `i'
	local lb = trim(string(r(mean),"%4.2f"))
	summ  auc_sk_u if skincat == `i'
	local ub = trim(string(r(mean),"%4.2f"))	
	putexcel G`j' = ("`est' (`lb', `ub')")
}
*overall skin tones
forval o = 1/5{
	summ auc_ox   if o == `o'
	local est = trim(string(r(mean),"%4.2f"))
	summ  auc_ox_l  if o == `o'
	local lb = trim(string(r(mean),"%4.2f"))
	summ  auc_ox_u if o == `o'
	local ub = trim(string(r(mean),"%4.2f"))
	if `o' == 1 {
		putexcel B7 = ("`est' (`lb', `ub')")
	}
	if `o' == 2 {
		putexcel C7 = ("`est' (`lb', `ub')")
	}
	if `o' == 3 {
		putexcel D7 = ("`est' (`lb', `ub')")
	}
	if `o' == 4 {
		putexcel E7 = ("`est' (`lb', `ub')")
	}
	if `o' == 5 {
		putexcel F7 = ("`est' (`lb', `ub')")
	}
}
* overall on both
local est = trim(string(overall[1,3],"%4.2f"))
local lb = trim(string(overall[5,3],"%4.2f"))
local ub = trim(string(overall[6,3],"%4.2f"))	

putexcel G7 = ("`est' (`lb', `ub')")
