/*******************************************************************************
Project: EXAKT
Do file for: Unadjusted diagnostic accuracy (Sn, Sp, FPR, FNR, AUC)
*******************************************************************************/
* config
version 17
set varabbrev off
set more off

*import & transform data (copied from do 3 to save rerunning all regressions)
use EXAKT$ExtractDate , clear
reshape long OXIMETER_ SPO2_OXI, i(Label RepeatNumber) j(oximeter_n)
bysort Label oximeter_n (OXIMETER_): replace OXIMETER_ = OXIMETER_[_N]
encode OXIMETER_ if !inlist(OXIMETER_,"-1","-2","-3"), gen(o)
lab var o "Pulse oximeter model"

g spfrac = SPO2_OXI/100
lab var spfrac "SpO2 fraction"

g safrac = round(SAO2_PDC,1)/100
lab var safrac "SaO2 fraction"
	
generate byte pid=1 if _n==1
replace pid=pid[_n-1] + (Label!=Label[_n-1]) if _n > 1
	
g byte sn92 = spfrac >= float(0.92) & safrac < float(0.92) if !mi(spfrac, safrac)
lab var sn92 "Sensitivity at 92"
g byte sp92 = spfrac < float(0.92) & safrac >= float(0.92) if !mi(safrac, safrac)
lab var sp92 "Specificity of 92"
g byte sn94 = spfrac >= float(0.94) & safrac < float(0.92) if !mi(spfrac, safrac)
lab var sn94 "Sensitivity at 94"
g byte sp94 = spfrac < float(0.94) & safrac >= float(0.94) if !mi(safrac, safrac)
lab var sp94 "Specificity of 94"
g byte oh = spfrac >= float(0.94) & safrac < float(0.88) if !mi(spfrac, safrac)
lab var oh "Occult hypoxaemia"

g spfrac_reverse = 1 - spfrac 
lab var spfrac_reverse "1 - SpO2"
g sa92orless = safrac <= float(0.92)
lab var sa92orless "SaO2 < 92"	
	
replace HB = . if HB < 0
	
keep if  !mi(spfrac, safrac, ITA, HB) // Restricting to full data

recode skincat (6=5)

* Duplicating for overall rows and columns
expand 2, gen(tag_ove)
replace o = 6 if tag_ove == 1
drop tag_ove 
expand 2, gen(tag_skin) 
replace skincat = 0 if tag_skin == 1

** Doing each of sensitivity/FNR and Specificty/FPR (inverses) at both 92 and 94 SAO2 values

putexcel set "${OutputDir}\\Diagnostic accuracy - FNR", modify sheet("92 Raw")	
excel
forval i = 0/5{
	di "***********  Skin tone: `i' ****************"
	local j = 7 - `i'
	forval o = 1/6{
		count if o == `o' & safrac < float(0.92) & skincat == `i' & !mi(sn92)
		local N = r(N)
		count if o == `o' & safrac < float(0.92) & skincat == `i' & sn92 == 1 
		local n = r(N)
		local p = trim(string(100*`n'/`N',"%4.1f"))
		if `o' == 1 {
			putexcel B`j' = ("`p' (`n'/`N')")
		}
		if `o' == 2 {
			putexcel C`j' = ("`p' (`n'/`N')")
		}
		if `o' == 3 {
			putexcel D`j' = ("`p' (`n'/`N')")
		}
		if `o' == 4 {
			putexcel E`j' = ("`p' (`n'/`N')")
		}
		if `o' == 5 {
			putexcel F`j' = ("`p' (`n'/`N')")
		}
		if `o' == 6 {
			putexcel G`j' = ("`p' (`n'/`N')")
		}
	}
}

putexcel set "${OutputDir}\\Diagnostic accuracy - Sensitivity", modify sheet("92 Raw")	
excel

forval i = 0/5{
	di "***********  Skin tone: `i' ****************"
	local j = 7 - `i'
	forval o = 1/6{
		count if o == `o' & safrac < float(0.92) & skincat == `i' & !mi(sn92)
		local N = r(N)
		count if o == `o' & safrac < float(0.92) & skincat == `i' & sn92 == 0
		local n = r(N)
		local p = trim(string(100*`n'/`N',"%4.1f"))
		if `o' == 1 {
			putexcel B`j' = ("`p' (`n'/`N')")
		}
		if `o' == 2 {
			putexcel C`j' = ("`p' (`n'/`N')")
		}
		if `o' == 3 {
			putexcel D`j' = ("`p' (`n'/`N')")
		}
		if `o' == 4 {
			putexcel E`j' = ("`p' (`n'/`N')")
		}
		if `o' == 5 {
			putexcel F`j' = ("`p' (`n'/`N')")
		}
		if `o' == 6 {
			putexcel G`j' = ("`p' (`n'/`N')")
		}
	}
}
	
putexcel set "${OutputDir}\\Diagnostic accuracy - FPR", modify sheet("92 Raw")	
excel
forval i = 0/5{
	di "***********  Skin tone: `i' ****************"
	local j = 7 - `i'
	forval o = 1/6{
		count if o == `o' & safrac >= float(0.92) & skincat == `i' & !mi(sp92)
		local N = r(N)
		count if o == `o' & safrac >= float(0.92) & skincat == `i' & sp92 == 1 
		local n = r(N)
		local p = trim(string(100*`n'/`N',"%4.1f"))
		if `o' == 1 {
			putexcel B`j' = ("`p' (`n'/`N')")
		}
		if `o' == 2 {
			putexcel C`j' = ("`p' (`n'/`N')")
		}
		if `o' == 3 {
			putexcel D`j' = ("`p' (`n'/`N')")
		}
		if `o' == 4 {
			putexcel E`j' = ("`p' (`n'/`N')")
		}
		if `o' == 5 {
			putexcel F`j' = ("`p' (`n'/`N')")
		}
		if `o' == 6 {
			putexcel G`j' = ("`p' (`n'/`N')")
		}
	}
}
	
putexcel set "${OutputDir}\\Diagnostic accuracy - Specificity", modify sheet("92 Raw")	
excel
forval i = 0/5{
	di "***********  Skin tone: `i' ****************"
	local j = 7 - `i'
	forval o = 1/6{
		count if o == `o' & safrac >= float(0.92) & skincat == `i' & !mi(sp92)
		local N = r(N)
		count if o == `o' & safrac >= float(0.92) & skincat == `i' & sp92 == 0
		local n = r(N)
		local p = trim(string(100*`n'/`N',"%4.1f"))
		if `o' == 1 {
			putexcel B`j' = ("`p' (`n'/`N')")
		}
		if `o' == 2 {
			putexcel C`j' = ("`p' (`n'/`N')")
		}
		if `o' == 3 {
			putexcel D`j' = ("`p' (`n'/`N')")
		}
		if `o' == 4 {
			putexcel E`j' = ("`p' (`n'/`N')")
		}
		if `o' == 5 {
			putexcel F`j' = ("`p' (`n'/`N')")
		}
		if `o' == 6 {
			putexcel G`j' = ("`p' (`n'/`N')")
		}
	}
}

putexcel set "${OutputDir}\\Diagnostic accuracy - FNR", modify sheet("94 Raw")	
excel
forval i = 0/5{
	di "***********  Skin tone: `i' ****************"
	local j = 7 - `i'
	forval o = 1/6{
		count if o == `o' & safrac < float(0.92) & skincat == `i' & !mi(sn94)
		local N = r(N)
		count if o == `o' & safrac < float(0.92) & skincat == `i' & sn94== 1 
		local n = r(N)
		local p = trim(string(100*`n'/`N',"%4.1f"))
		if `o' == 1 {
			putexcel B`j' = ("`p' (`n'/`N')")
		}
		if `o' == 2 {
			putexcel C`j' = ("`p' (`n'/`N')")
		}
		if `o' == 3 {
			putexcel D`j' = ("`p' (`n'/`N')")
		}
		if `o' == 4 {
			putexcel E`j' = ("`p' (`n'/`N')")
		}
		if `o' == 5 {
			putexcel F`j' = ("`p' (`n'/`N')")
		}
		if `o' == 6 {
			putexcel G`j' = ("`p' (`n'/`N')")
		}
	}
}

putexcel set "${OutputDir}\\Diagnostic accuracy - Sensitivity", modify sheet("94 Raw")	
excel

forval i = 0/5{
	di "***********  Skin tone: `i' ****************"
	local j = 7 - `i'
	forval o = 1/6{
		count if o == `o' & safrac < float(0.92) & skincat == `i' & !mi(sn94)
		local N = r(N)
		count if o == `o' & safrac < float(0.92) & skincat == `i' & sn94 == 0
		local n = r(N)
		local p = trim(string(100*`n'/`N',"%4.1f"))
		if `o' == 1 {
			putexcel B`j' = ("`p' (`n'/`N')")
		}
		if `o' == 2 {
			putexcel C`j' = ("`p' (`n'/`N')")
		}
		if `o' == 3 {
			putexcel D`j' = ("`p' (`n'/`N')")
		}
		if `o' == 4 {
			putexcel E`j' = ("`p' (`n'/`N')")
		}
		if `o' == 5 {
			putexcel F`j' = ("`p' (`n'/`N')")
		}
		if `o' == 6 {
			putexcel G`j' = ("`p' (`n'/`N')")
		}
	}
}
	
putexcel set "${OutputDir}\\Diagnostic accuracy - FPR", modify sheet("94 Raw")
excel	
forval i = 0/5{
	di "***********  Skin tone: `i' ****************"
	local j = 7 - `i'
	forval o = 1/6{
		count if o == `o' & safrac >= float(0.92) & skincat == `i' & !mi(sp94)
		local N = r(N)
		count if o == `o' & safrac >= float(0.92) & skincat == `i' & sp94 == 1 
		local n = r(N)
		local p = trim(string(100*`n'/`N',"%4.1f"))
		if `o' == 1 {
			putexcel B`j' = ("`p' (`n'/`N')")
		}
		if `o' == 2 {
			putexcel C`j' = ("`p' (`n'/`N')")
		}
		if `o' == 3 {
			putexcel D`j' = ("`p' (`n'/`N')")
		}
		if `o' == 4 {
			putexcel E`j' = ("`p' (`n'/`N')")
		}
		if `o' == 5 {
			putexcel F`j' = ("`p' (`n'/`N')")
		}
		if `o' == 6 {
			putexcel G`j' = ("`p' (`n'/`N')")
		}
	}
}
	
putexcel set "${OutputDir}\\Diagnostic accuracy - Specificity", modify sheet("94 Raw")	
excel
forval i = 0/5{
	di "***********  Skin tone: `i' ****************"
	local j = 7 - `i'
	forval o = 1/6{
		count if o == `o' & safrac >= float(0.92) & skincat == `i' & !mi(sp94)
		local N = r(N)
		count if o == `o' & safrac >= float(0.92) & skincat == `i' & sp94 == 0
		local n = r(N)
		local p = trim(string(100*`n'/`N',"%4.1f"))
		if `o' == 1 {
			putexcel B`j' = ("`p' (`n'/`N')")
		}
		if `o' == 2 {
			putexcel C`j' = ("`p' (`n'/`N')")
		}
		if `o' == 3 {
			putexcel D`j' = ("`p' (`n'/`N')")
		}
		if `o' == 4 {
			putexcel E`j' = ("`p' (`n'/`N')")
		}
		if `o' == 5 {
			putexcel F`j' = ("`p' (`n'/`N')")
		}
		if `o' == 6 {
			putexcel G`j' = ("`p' (`n'/`N')")
		}
	}
}

** Occult hypoxaemia - sao2 < 0.88 & spo2 >= 0.92
putexcel set "${OutputDir}\\Diagnostic accuracy - Occult Hypoxaemia", modify sheet("Raw")
excel	
forval i = 0/5{
	di "***********  Skin tone: `i' ****************"
	local j = 7 - `i'
	forval o = 1/6{
		count if o == `o' & safrac < float(0.88) & skincat == `i' & !mi(oh)
		local N = r(N)
		count if o == `o' & safrac < float(0.88) & skincat == `i' & oh == 1 
		local n = r(N)
		local p = trim(string(100*`n'/`N',"%4.1f"))
		if `o' == 1 {
			putexcel B`j' = ("`p' (`n'/`N')")
		}
		if `o' == 2 {
			putexcel C`j' = ("`p' (`n'/`N')")
		}
		if `o' == 3 {
			putexcel D`j' = ("`p' (`n'/`N')")
		}
		if `o' == 4 {
			putexcel E`j' = ("`p' (`n'/`N')")
		}
		if `o' == 5 {
			putexcel F`j' = ("`p' (`n'/`N')")
		}
		if `o' == 6 {
			putexcel G`j' = ("`p' (`n'/`N')")
		}
	}
}

* Using a rocreg model with only sao2 and spo2 values in it to get a raw estimate
putexcel set "${OutputDir}\\Diagnostic accuracy - AUROC", modify sheet("Raw")	
excel
forval i = 0/5{
	di "***********  Skin tone: `i' ****************"
	local j = 7 - `i'
	forval o = 1/6{
		rocreg sa92orless spfrac_reverse if skincat == `i' & o == `o', probit ml cluster(pid)
		local est = trim(string(r(table)[1,3],"%4.2f"))
		local lb = trim(string(r(table)[5,3],"%4.2f"))
		local ub = trim(string(r(table)[6,3],"%4.2f"))
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
		if `o' == 6 {
			putexcel G`j' = ("`est' (`lb', `ub')")
		}
	}
}