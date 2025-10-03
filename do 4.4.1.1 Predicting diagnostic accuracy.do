/*******************************************************************************
Project: EXAKT
Do file for: Adjusted diagnostic accuracy (Sn, Sp, FPR, FNR, AUC)
*******************************************************************************/

cap log close
log using PredictingDiagnostic, text replace

* config
cd "S:\Stats\7. Confidential\Trials\UK-ROX\EXAKT"
version 17
set varabbrev off
set more off
set seed 34261112

* import data
use EXAKT${ExtractDate}_postregression, clear
recode skincat (6=5)
* recreate ITA & SaO2 knot matrix (needed unless do 3 is run first, in same stata session)
mkspline temp = ITA, cubic nk(4) 
mat tk = r(knots)
drop temp?

* store subdistrubtions of SaO2 among cases and non-cases for sensitivity and specificty and occult hypoxaemia
// using random sample of 100 to speed up predictions
preserve
	keep if safrac<=float(0.92) & !mi(spfrac)
	keep s? SiteNumber pid sp??orless
	g cases = "Yes"
	g byte n = 1
	g double rand = runiform()
	sort rand
	drop rand
	keep if _n<=100
	tempfile sa
	save `sa'
restore, preserve
	keep if safrac>float(0.92) & !mi(safrac) & !mi(spfrac)
	keep s? SiteNumber pid sp??orless
	g cases = "No"
	g byte n = 1
	g double rand = runiform()
	sort rand
	drop rand
	keep if _n<=100
	append using `sa'
	save `sa', replace
restore, preserve
	keep if safrac<float(0.88) & !mi(safrac) & !mi(spfrac)
	keep s? SiteNumber pid sp??orless
	g cases = "Occult"
	g byte n = 1
	g double rand = runiform()
	sort rand
	drop rand
	keep if _n<=100
	append using `sa'
	save `sa', replace
restore

******************* only requires ITA and h ***********************
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

* store median l-a-b & RGB values for each level of ITA
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


replace n = 1

* Getting full list of SAO2 to predict over 
joinby n using `sa'

** Predict and get results for estimate and CI's
foreach v in sp92orless sp94orless{
	estimates use `v'
	predict `v'_xb, xb
	g `v'_pr = invlogit(`v'_xb)
	predict `v'_se, stdp	
	g `v'_lb = invlogit(`v'_xb - 1.96* `v'_se)
	g `v'_ub = invlogit(`v'_xb + 1.96* `v'_se)
	foreach v of varlist `v'_pr `v'_ub `v'_lb {
		replace `v' = `v'*100
	}
}

** Replace positive and negatives for outputs
foreach v of varlist sp92orless_pr sp92orless_lb sp92orless_ub sp94orless_pr sp94orless_lb sp94orless_ub {
	replace `v' = 100 - `v' if cases == "No" | cases == "Occult"
}

** Expanding for columns and rows totals
levelsof skincat, local(skincats)
expand 2, gen(ox)
replace ox = o if ox == 1
expand 2, gen(sk)
replace sk = skincat if sk == 1

* Loop over SAO2 values 
* All of Sensitivity/Specificity/FNR/FPR/Occult hypoxaemia outputted by this
foreach sp in 92 94 {
	* estimate Sensitivity
	putexcel set "${OutputDir}\\Diagnostic accuracy - Sensitivity", modify sheet("Adjusted `sp'")
	// drop t?
	forval i = 0/5 {
		di "***********  Skin tone: `i' ****************"
		local j = 7 - `i'
		forval o = 0/5{
			summ sp`sp'orless_pr if ox == `o' & sk == `i' & cases == "Yes"
			local est = trim(string(r(mean),"%3.1f"))
			summ sp`sp'orless_lb if ox == `o' & sk == `i' & cases == "Yes"
			local lb = trim(string(r(mean),"%3.1f"))
			summ sp`sp'orless_ub if ox == `o' & sk == `i' & cases == "Yes"
			local ub = trim(string(r(mean),"%3.1f"))
			if `o' == 0 {
				putexcel G`j' = ("`est' (`lb', `ub')")
			}
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
		
	}
	
		* estimate False Negative Rate
	putexcel set "${OutputDir}\\Diagnostic accuracy - FNR", modify sheet("Adjusted `sp'")
	// drop t?
	forval i = 0/5 {
		di "***********  Skin tone: `i' ****************"
		local j = 7 - `i'
		forval o = 0/5{
			summ sp`sp'orless_pr if ox == `o' & sk == `i' & cases == "Yes"
			local est = trim(string(100-r(mean),"%3.1f"))
			summ sp`sp'orless_lb if ox == `o' & sk == `i' & cases == "Yes"
			local ub = trim(string(100-r(mean),"%3.1f"))
			summ sp`sp'orless_ub if ox == `o' & sk == `i' & cases == "Yes"
			local lb = trim(string(100-r(mean),"%3.1f"))
			if `o' == 0 {
				putexcel G`j' = ("`est' (`lb', `ub')")
			}
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
		
	}
	* estimate Specificity
	putexcel set "${OutputDir}\\Diagnostic accuracy - Specificity", modify sheet("Adjusted `sp'")
	// drop t?
	forval i = 0/5 {
		di "***********  Skin tone: `i' ****************"
		local j = 7 - `i'
		forval o = 0/5{
			summ sp`sp'orless_pr if ox == `o' & sk == `i' & cases == "No"
			local est = trim(string(r(mean),"%3.1f"))
			summ sp`sp'orless_lb if ox == `o' & sk == `i' & cases == "No"
			local lb = trim(string(r(mean),"%3.1f"))
			summ sp`sp'orless_ub if ox == `o' & sk == `i' & cases == "No"
			local ub = trim(string(r(mean),"%3.1f"))
			if `o' == 0 {
				putexcel G`j' = ("`est' (`ub', `lb')")
			}
			if `o' == 1 {
				putexcel B`j' = ("`est' (`ub', `lb')")
			}
			if `o' == 2 {
				putexcel C`j' = ("`est' (`ub', `lb')")
			}
			if `o' == 3 {
				putexcel D`j' = ("`est' (`ub', `lb')")
			}
			if `o' == 4 {
				putexcel E`j' = ("`est' (`ub', `lb')")
			}
			if `o' == 5 {
				putexcel F`j' = ("`est' (`ub', `lb')")
			}
		}	
	}	
		* estimate False Positive Rate
	putexcel set "${OutputDir}\\Diagnostic accuracy - FPR", modify sheet("Adjusted `sp'")
	// drop t?
	forval i = 0/5 {
		di "***********  Skin tone: `i' ****************"
		local j = 7 - `i'
		forval o = 0/5{
			summ sp`sp'orless_pr if ox == `o' & sk == `i' & cases == "No"
			local est = trim(string(100-r(mean),"%3.1f"))
			summ sp`sp'orless_lb if ox == `o' & sk == `i' & cases == "No"
			local ub = trim(string(100-r(mean),"%3.1f"))
			summ sp`sp'orless_ub if ox == `o' & sk == `i' & cases == "No"
			local lb = trim(string(100-r(mean),"%3.1f"))
			if `o' == 0 {
				putexcel G`j' = ("`est' (`ub', `lb')")
			}
			if `o' == 1 {
				putexcel B`j' = ("`est' (`ub', `lb')")
			}
			if `o' == 2 {
				putexcel C`j' = ("`est' (`ub', `lb')")
			}
			if `o' == 3 {
				putexcel D`j' = ("`est' (`ub', `lb')")
			}
			if `o' == 4 {
				putexcel E`j' = ("`est' (`ub', `lb')")
			}
			if `o' == 5 {
				putexcel F`j' = ("`est' (`ub', `lb')")
			}
		}	
	}	
}

* estimate Occult hypoxaemia
putexcel set "${OutputDir}\\Diagnostic accuracy - Occult Hypoxaemia", modify sheet("Adjusted")
forval i = 0/5 {
	di "***********  Skin tone: `i' ****************"
	local j = 7 - `i'
	forval o = 0/5{
		summ sp92orless_pr if ox == `o' & sk == `i' & cases == "Occult"
		local est = trim(string(r(mean),"%3.1f"))
		summ sp92orless_lb if ox == `o' & sk == `i' & cases == "Occult"
		local lb = trim(string(r(mean),"%3.1f"))
		summ sp92orless_ub if ox == `o' & sk == `i' & cases == "Occult"
		local ub = trim(string(r(mean),"%3.1f"))
		if `o' == 0 {
			putexcel G`j' = ("`est' (`ub', `lb')")
		}
		if `o' == 1 {
			putexcel B`j' = ("`est' (`ub', `lb')")
		}
		if `o' == 2 {
			putexcel C`j' = ("`est' (`ub', `lb')")
		}
		if `o' == 3 {
			putexcel D`j' = ("`est' (`ub', `lb')")
		}
		if `o' == 4 {
			putexcel E`j' = ("`est' (`ub', `lb')")
		}
		if `o' == 5 {
			putexcel F`j' = ("`est' (`ub', `lb')")
		}
	}	
}	


log close