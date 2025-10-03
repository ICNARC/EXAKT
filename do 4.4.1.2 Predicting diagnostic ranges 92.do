/*******************************************************************************
Project: EXAKT
Do file for: Adjusted Sn and Sp at threshold of SpO2=92
*******************************************************************************/

* config
cd "S:\Stats\7. Confidential\Trials\UK-ROX\EXAKT"
version 17
set varabbrev off
set more off
//global PPIExtractDate "20241118"
log using "${LogDir}\PredictingDiagRanges92", replace text
set seed 34261112

* import data
use EXAKT${ExtractDate}_postregression, clear
recode skincat (6=5)


* recreate ITA & SaO2 knot matrix (needed unless do 3 is run first, in same stata session)
mkspline temp = ITA, cubic nk(4) 
mat tk = r(knots)
drop temp?

* store subdistrubtions of SaO2 among cases and non-cases for sensitivity and specificty
// using random sample of 100 to speed up predictions
preserve
	keep if safrac<=float(0.92) & !mi(spfrac)
	keep s? SiteNumber pid sp??orless
	g cases = "FNR"
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
	g cases = "FPR"
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


replace n = 1

joinby n using `sa'

save diag_range_data,replace

* Import only data for modelling
use EXAKT${ExtractDate}_postregression if !mi(spfrac, safrac, ITA, HB), clear
recode skincat (6=5)

cap prog drop pr_diag
prog pr_diag, rclass 
	** Running the analysis model for sp92 or less 
	melogit sp92orless t? s? c.t1#c.s1 c.t1#c.s2 c.t1#c.s3 c.t2#c.s1 c.t3#c.s1 ///
		i.o i.o#c.t1 i.o#c.t2 i.o#c.t3 i.o#c.s1 i.o#c.s2 i.o#c.s3 ///
		h?	|| SiteNumber: || pid: // sample too small to include RepeatNumber?	
	* Estimate estimates at light and dark skin tones and find difference between the 2
	preserve
		use diag_range_data,clear
		predict sp92_xb, xb
		g sp92_pr = 100*invlogit(sp92_xb)
		foreach c in "FNR" "FPR" "Occult" {
			foreach i in 1 5 {
				forval j = 1/5 {
					summ sp92_pr if cases == "`c'" & skincat == `i' & o == `j'
					local `c'_`i'_`j' = r(mean)						
				}
				summ sp92_pr if cases == "`c'" & skincat == `i'
				local `c'_`i' = r(mean)				
			}
			forval j = 1/5 {
				local `c'_range_`j' = ``c'_1_`j'' - ``c'_5_`j''
				return scalar `c'_range_`j' = ``c'_range_`j''			
			}
			local `c'_range = ``c'_1' - ``c'_5'
			return scalar `c'_range = ``c'_range'
		}
	restore
end

bootstrap r(FNR_range_1) r(FNR_range_2) r(FNR_range_3) ///
		  r(FNR_range_4) r(FNR_range_5) r(FNR_range)   ///
		  r(FPR_range_1) r(FPR_range_2) r(FPR_range_3) ///
		  r(FPR_range_4) r(FPR_range_5) r(FPR_range)   ///
		  r(Occult_range_1) r(Occult_range_2) r(Occult_range_3) ///
		  r(Occult_range_4) r(Occult_range_5) r(Occult_range)   ///
		  , reps($bsreps): pr_diag

matrix results = r(table)		  

** Output all results (Using fact of inverse relationship between FNR and sensitivity / FPR and Specificity
* estimate Sensitivity
putexcel set "${OutputDir}\\Diagnostic accuracy - FNR", modify sheet("Adjusted 92")		  
forval i = 1/6 {
	local est = trim(string(-1*results[1,`i'],"%3.1f"))
	local lb = trim(string(-1*results[6,`i'],"%3.1f"))
	local ub = trim(string(-1*results[5,`i'],"%3.1f"))
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

putexcel set "${OutputDir}\\Diagnostic accuracy - Sensitivity", modify sheet("Adjusted 92")		  
forval i = 1/6 {
	local est = trim(string(results[1,`i'],"%3.1f"))
	local lb = trim(string(results[5,`i'],"%3.1f"))
	local ub = trim(string(results[6,`i'],"%3.1f"))
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

* estimate Sensitivity
putexcel set "${OutputDir}\\Diagnostic accuracy - FPR", modify sheet("Adjusted 92")		  
forval i = 7/12 {
	local est = trim(string(results[1,`i'],"%3.1f"))
	local lb = trim(string(results[5,`i'],"%3.1f"))
	local ub = trim(string(results[6,`i'],"%3.1f"))
	if `i' == 7 {
		putexcel B8 = ("`est' (`lb', `ub')")
	}
	if `i' == 8 {
		putexcel C8 = ("`est' (`lb', `ub')")
	}
	if `i' == 9 {
		putexcel D8 = ("`est' (`lb', `ub')")
	}
	if `i' == 10 {
		putexcel E8 = ("`est' (`lb', `ub')")
	}
	if `i' == 11 {
		putexcel F8 = ("`est' (`lb', `ub')")
	}		
	if `i' == 12 {
		putexcel G8 = ("`est' (`lb', `ub')")
	}	
}

putexcel set "${OutputDir}\\Diagnostic accuracy - Specificity", modify sheet("Adjusted 92")		  
forval i = 7/12 {
	local est = trim(string(-1*results[1,`i'],"%3.1f"))
	local lb = trim(string(-1*results[6,`i'],"%3.1f"))
	local ub = trim(string(-1*results[5,`i'],"%3.1f"))
	if `i' == 7 {
		putexcel B8 = ("`est' (`lb', `ub')")
	}
	if `i' == 8 {
		putexcel C8 = ("`est' (`lb', `ub')")
	}
	if `i' == 9 {
		putexcel D8 = ("`est' (`lb', `ub')")
	}
	if `i' == 10 {
		putexcel E8 = ("`est' (`lb', `ub')")
	}
	if `i' == 11 {
		putexcel F8 = ("`est' (`lb', `ub')")
	}		
	if `i' == 12 {
		putexcel G8 = ("`est' (`lb', `ub')")
	}	
}

* estimate Sensitivity
putexcel set "${OutputDir}\\Diagnostic accuracy - Occult Hypoxaemia", modify sheet("Adjusted")		  
forval i = 13/18 {
	local est = trim(string(-1*results[1,`i'],"%3.1f"))
	local lb = trim(string(-1*results[6,`i'],"%3.1f"))
	local ub = trim(string(-1*results[5,`i'],"%3.1f"))
	if `i' == 13 {
		putexcel B8 = ("`est' (`lb', `ub')")
	}
	if `i' == 14 {
		putexcel C8 = ("`est' (`lb', `ub')")
	}
	if `i' == 15 {
		putexcel D8 = ("`est' (`lb', `ub')")
	}
	if `i' == 16 {
		putexcel E8 = ("`est' (`lb', `ub')")
	}
	if `i' == 17 {
		putexcel F8 = ("`est' (`lb', `ub')")
	}		
	if `i' == 18 {
		putexcel G8 = ("`est' (`lb', `ub')")
	}	
}
log close