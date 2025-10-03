/*******************************************************************************
Project: EXAKT
Do file for: Differences across skin tone categories in adjusted AUROC
*******************************************************************************/

* config
cd "S:\Stats\7. Confidential\Trials\UK-ROX\EXAKT"
version 17
set varabbrev off
set more off
set seed 34261112
log using "${LogDir}\PredictingDiagRangesAUC", replace text

* import data
use EXAKT${ExtractDate}_postregression, clear
recode skincat (6=5)

******************* auroc plot - only requires ITA and h ***********************
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
keep if RepeatNumber==1 & oximeter_n==1 & inlist(skincat,1,5)
collapse (median) t?, by(skincat)
// append using `minmax'

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
	
save auroc_range_data,replace

* Import only data for modelling
use EXAKT${ExtractDate}_postregression if !mi(spfrac, safrac, ITA, HB), clear
recode skincat (6=5)

* Program estimating the AUROC over all oximeters and overall
cap prog drop pr_diag
prog pr_diag, rclass 
	rocreg sa92orless spfrac_reverse, probit ml cluster(pid) ctrlcov(h?) /// 
		roccov(o2 o3 o4 o5 t1 t2 t3 ///
			o2t1 o3t1 o4t1 o5t1 ///
			o2t2 o3t2 o4t2 o5t2 ///
			o2t3 o3t3 o4t3 o5t3) //
	preserve
		use auroc_range_data,clear
		predict auc
		forval j = 1/5 {
			foreach i in 1 5 {
				summ auc if skincat == `i' & o == `j', meanonly
				local auc_`i'_`j' = r(mean)						
			}			
			local auc_range_`j' = `auc_1_`j'' - `auc_5_`j''
			return scalar auc_range_`j' = `auc_range_`j''			
		}
	restore
	
	rocreg sa92orless spfrac_reverse, probit ml cluster(pid) roccov(t?) ctrlcov(h?) 
	preserve
		use auroc_range_data,clear
		predict auc
		foreach i in 1 5 {
			summ auc if skincat == `i', meanonly
			local auc_`i' = r(mean)								
		}
		local auc_range = `auc_1' - `auc_5'
		return scalar auc_range = `auc_range'			
	restore	
end

bootstrap r(auc_range_1) r(auc_range_2) r(auc_range_3) ///
		  r(auc_range_4) r(auc_range_5) r(auc_range)   ///
		  , reps($bsreps): pr_diag

matrix results = r(table)		  
		  
* estimate AUROX
putexcel set "${OutputDir}\\Diagnostic accuracy - AUROC", modify sheet("Adjusted")		  
forval i = 1/6 {
	local est = trim(string(results[1,`i'],"%4.2f"))
	local lb = trim(string(results[5,`i'],"%4.2f"))
	local ub = trim(string(results[6,`i'],"%4.2f"))
	if `i' == 1 {
		putexcel B8 = ("`est' (`lb', `ub')")
	}
	if `i' == 2 {
		putexcel C8 = ("`est' (`lb', `ub')")
	}
	if `i' == 3 {
		putexcel D8 = ("`est' (`lb', `ub')")
	}
	if `i' == 4 {
		putexcel E8 = ("`est' (`lb', `ub')")
	}
	if `i' == 5 {
		putexcel F8 = ("`est' (`lb', `ub')")
	}		
	if `i' == 6 {
		putexcel G8 = ("`est' (`lb', `ub')")
	}	
}

log close