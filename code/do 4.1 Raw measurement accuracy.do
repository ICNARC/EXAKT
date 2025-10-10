/*******************************************************************************
Project: EXAKT
Do file for: Getting raw unadjusetd figures of measurement accuracy
*******************************************************************************/

* config
version 17
set varabbrev off
set more off

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
	
* encode patient pseudoidentifer
sort Label
generate byte pid=1 if _n==1
replace pid=pid[_n-1] + (Label!=Label[_n-1]) if _n > 1
	
g mse = (spfrac-safrac)^2
lab var mse "mean square error"
	
g bias = (spfrac-safrac)
lab var bias "bias"
	
estimates use fracreg
predict sp_pr_overall
g precision = (spfrac - sp_pr_overall)^2 
lab var precision "precision"


recode skincat (6=5)

* Duplicating to add overall columns and rows
expand 2, gen(tag_ove)
replace o = 6 if tag_ove == 1
drop tag_ove 
expand 2, gen(tag_skin) 
replace skincat = 0 if tag_skin == 1



levelsof skincat, local(skincats)	

*** RAW bias - loop through results and output each 
putexcel set "${OutputDir}\\Measurement accuracy - Bias", modify sheet("Raw")	
foreach i in `skincats'{
	di "***********  Skin tone: `i' ****************"
	local j = 7 - `i'
	forval o = 1/6{
		mean bias spfrac safrac if o == `o' & skincat == `i', vce(cluster pid)
		// Store the results in local macros
		matrix results = r(table)
		local mean = results[1,1]
		local mean_sp = results[1,2]	
		local mean_sa = results[1,3]	
		
		// Format the result
		local result = string(`mean'*100, "%9.1f") + " (" + string(`mean_sp'*100, "%9.1f") + " - " + string(`mean_sa'*100, "%9.1f") + ")"
		if `o' == 1 {
			putexcel B`j' = ("`result'")
		}
		if `o' == 2 {
			putexcel C`j' = ("`result'")
		}
		if `o' == 3 {
			putexcel D`j' = ("`result'")
		}
		if `o' == 4 {
			putexcel E`j' = ("`result'")
		}
		if `o' == 5 {
			putexcel F`j' = ("`result'")
		}
		if `o' == 6 {
			putexcel G`j' = ("`result'")
		}
	}
}

* Bootstrapping confidence intervals
cap prog drop raw_precision
prog raw_precision, rclass
	summ precision, meanonly 
	return scalar mean = 100*sqrt(r(mean))
end	
	
*** RAW RMSE	
putexcel set "${OutputDir}\\Measurement accuracy - RMSE", modify sheet("Raw")	
forval i = 0/5{
	di "***********  Skin tone: `i' ****************"
	local j = 7 - `i'
	forval o = 1/6{
		preserve 
			keep if o == `o' & skincat == `i'
			bootstrap r(mean) , reps($bsreps) cluster(pid): raw_precision
		restore
		// Store the results in local macros
		local mean = r(table)[1,1]
 		local lb = r(table)[5,1]
 		local ub = r(table)[6,1]
		
		// Format the result
		local result = string(`mean', "%9.1f") + " (" + string(`lb', "%9.1f") + ", " + string(`ub', "%9.1f") + ")"
		if `o' == 1 {
			putexcel B`j' = ("`result'")
		}
		if `o' == 2 {
			putexcel C`j' = ("`result'")
		}
		if `o' == 3 {
			putexcel D`j' = ("`result'")
		}
		if `o' == 4 {
			putexcel E`j' = ("`result'")
		}
		if `o' == 5 {
			putexcel F`j' = ("`result'")
		}
		if `o' == 6 {
			putexcel G`j' = ("`result'")
		}
	}
}		

* Bootstrapping confidence intervals
cap prog drop raw_accuracy
prog raw_accuracy, rclass
	summ mse, meanonly 
	return scalar mean = 100*sqrt(r(mean))
end

*** RAW ARMS	
putexcel set "${OutputDir}\\Measurement accuracy - ARMS", modify sheet("Raw")	
foreach i in `skincats'{
	di "***********  Skin tone: `i' ****************"
	local j = 7 - `i'
	forval o = 1/6{
		preserve 
			keep if o == `o' & skincat == `i'
			bootstrap r(mean) , reps($bsreps) cluster(pid): raw_accuracy
		restore	
		// Store the results in local macros
		local mean = r(table)[1,1]
 		local lb = r(table)[5,1]
 		local ub = r(table)[6,1]
		
		// Format the result
		local result = string(`mean', "%9.1f") + " (" + string(`lb', "%9.1f") + ", " + string(`ub', "%9.1f") + ")"
		if `o' == 1 {
			putexcel B`j' = ("`result'")
		}
		if `o' == 2 {
			putexcel C`j' = ("`result'")
		}
		if `o' == 3 {
			putexcel D`j' = ("`result'")
		}
		if `o' == 4 {
			putexcel E`j' = ("`result'")
		}
		if `o' == 5 {
			putexcel F`j' = ("`result'")
		}
		if `o' == 6 {
			putexcel G`j' = ("`result'")
		}
	}
}		
