/*******************************************************************************
Project: EXAKT
Do file for: Adjusted Sn and Sp at threshold of SpO2=94
*******************************************************************************/

log using "${LogDir}\PredictingDiagRanges94", replace text


* Import only data for modelling
use EXAKT${ExtractDate}_postregression if !mi(spfrac, safrac, ITA, HB), clear
recode skincat (6=5)

cap prog drop pr_diag
prog pr_diag, rclass 
	melogit sp94orless t? s? c.t1#c.s1 c.t1#c.s2 c.t1#c.s3 c.t2#c.s1 c.t3#c.s1 ///
		i.o i.o#c.t1 i.o#c.t2 i.o#c.t3 i.o#c.s1 i.o#c.s2 i.o#c.s3 ///
		h?	|| SiteNumber: || pid: // sample too small to include RepeatNumber?	
	preserve
		use diag_range_data,clear
		predict sp94_xb, xb
		g sp94_pr = 100*invlogit(sp94_xb)
		foreach c in "FNR" "FPR" {
			foreach i in 1 5 {
				forval j = 1/5 {
					summ sp94_pr if cases == "`c'" & skincat == `i' & o == `j'
					local `c'_`i'_`j' = r(mean)						
				}
				summ sp94_pr if cases == "`c'" & skincat == `i'
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
		  , reps($bsreps): pr_diag

matrix results = r(table)		  
		  
* estimate Sensitivity
putexcel set "${OutputDir}\\Diagnostic accuracy - FNR", modify sheet("Adjusted 94")		  
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

putexcel set "${OutputDir}\\Diagnostic accuracy - Sensitivity", modify sheet("Adjusted 94")		  
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
putexcel set "${OutputDir}\\Diagnostic accuracy - FPR", modify sheet("Adjusted 94")		  
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

putexcel set "${OutputDir}\\Diagnostic accuracy - Specificity", modify sheet("Adjusted 94")		  
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
log close