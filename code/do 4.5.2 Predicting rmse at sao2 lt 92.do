/*******************************************************************************
Project: EXAKT
Do file for: Adjusted precision over SaO2 < 92
*******************************************************************************/

* Import only data for modelling
use EXAKT${ExtractDate}_postregression if !mi(spfrac, safrac, ITA, HB), clear
recode skincat (6=5)

* Reorder just to make life easier in outputting results
g skincat_rec = 6-skincat 
drop skincat 
ren skincat_rec skincat

keep pid spfrac safrac t1 t2 t3 s1 s2 s3 h1 h2 h3 o skincat SquaredDeviation

* Getting median ITAs for each skin tone, as well as values of splines for different sao2
forval i = 1/3{
	forval j = 1/5{
		sum t`i' if skincat == `j',detail
		global t`i'_`j' = r(p50)		
	}
}

** Getting a list of all Safrac less than
preserve 
	keep if safrac <= float(92/100)
	keep safrac s1 s2 s3
	ren * *_92
	expand 7
	g double rand = runiform()
	sort rand
	drop rand
	tempfile safrac
	save `safrac', replace
restore

cap drop _merge
merge 1:1 _n using `safrac', keep(3)

foreach var in s1 s2 s3 h1 h2 h3 t1 t2 t3 o {
	clonevar `var'_orig = `var'
}

* define bootstrap program
cap prog drop pr_rmse_sao2
prog pr_rmse_sao2, rclass
	
	* RMSE
	fracreg probit SquaredDeviation t? s? c.t1#c.s1 c.t1#c.s2 c.t1#c.s3 c.t2#c.s1 c.t3#c.s1 ///
		i.o i.o#c.t1 i.o#c.t2 i.o#c.t3 i.o#c.s1 i.o#c.s2 i.o#c.s3 ///
		h?, vce(cluster pid)	
	
	foreach var in s1 s2 s3 {
		replace `var' = `var'_92
	}
	
	* Loop over skin categories
	forval i = 1/5 {
		* Assign the ITA to median of the skincat
		foreach var in t1 t2 t3 {
			replace `var' = ${`var'_`i'}
		}
		* Loop over oximeters and predict
		forval j = 1/5 {
			replace o = `j'
			predict pred 
			summ pred, meanonly 
			loc o`j'_s`i' = r(mean)		
			drop pred
		}
		* overall
		replace o = o_orig
		predict pred 
		summ pred, meanonly 
		loc o6_s`i' = r(mean)		
		drop pred
	}
	
	* Replace ITA to original 
	foreach var in t1 t2 t3 {
		replace `var' = `var'_orig
	}	
	
	* Loop over oximeters
	forval i = 1/5{
		replace o = `i'
		predict pred 
		summ pred, meanonly 
		loc o`i'_s6 = r(mean)	
		drop pred
	}
	* Replace oximeters back to do overall
	replace o = o_orig
	predict pred 
	summ pred, meanonly 
	loc o6_s6 = r(mean)
	drop pred
	
	forval i = 1/6 {
		forval j = 1/6 {
			return scalar rmse_o`i'_s`j' = 100*sqrt(`o`i'_s`j'')
		}
	}
	
	*calculate difference for range
	forval i = 1/ 6 {
		return scalar rmse_range`i' = 100*(sqrt(`o`i'_s5') - sqrt(`o`i'_s1'))
	}		

	* Replace to originals 
	foreach var in s1 s2 s3 {
		replace `var' = `var'_orig
	}

end

	* run estimation
	bootstrap r(rmse_o1_s1) r(rmse_o1_s2) r(rmse_o1_s3) r(rmse_o1_s4) r(rmse_o1_s5) r(rmse_o1_s6) r(rmse_range1) ///
			  r(rmse_o2_s1) r(rmse_o2_s2) r(rmse_o2_s3) r(rmse_o2_s4) r(rmse_o2_s5) r(rmse_o2_s6) r(rmse_range2) ///
			  r(rmse_o3_s1) r(rmse_o3_s2) r(rmse_o3_s3) r(rmse_o3_s4) r(rmse_o3_s5) r(rmse_o3_s6) r(rmse_range3) ///
			  r(rmse_o4_s1) r(rmse_o4_s2) r(rmse_o4_s3) r(rmse_o4_s4) r(rmse_o4_s5) r(rmse_o4_s6) r(rmse_range4) ///
			  r(rmse_o5_s1) r(rmse_o5_s2) r(rmse_o5_s3) r(rmse_o5_s4) r(rmse_o5_s5) r(rmse_o5_s6) r(rmse_range5) ///
			  r(rmse_o6_s1) r(rmse_o6_s2) r(rmse_o6_s3) r(rmse_o6_s4) r(rmse_o6_s5) r(rmse_o6_s6) r(rmse_range6) ///
			, reps($bsreps): pr_rmse_sao2


	putexcel set "${OutputDir}\\Measurement accuracy 92 - RMSE", modify sheet("Adjusted <=92")
	forval i = 1/6 {
		forval j = 1/7 {
			local matrow = (`i'-1)*7 + `j' 
			local row = `j' + 1
			local est = trim(string(r(table)[1,`matrow'] , "%3.1f"))
			local lb = trim(string(r(table)[5,`matrow'] , "%3.1f"))
			local ub = trim(string(r(table)[6,`matrow'] , "%3.1f"))
			if `i' == 1 { 
				putexcel B`row' = ("`est' (`lb', `ub')")
			}
			if `i' == 2 {
				putexcel C`row' = ("`est' (`lb', `ub')")
			}
			if `i' == 3 {
				putexcel D`row' = ("`est' (`lb', `ub')")
			}
			if `i' == 4 {
				putexcel E`row' = ("`est' (`lb', `ub')")
			}
			if `i' == 5 {
				putexcel F`row' = ("`est' (`lb', `ub')")
			}	
			if `i' == 6 {
				putexcel G`row' = ("`est' (`lb', `ub')")
			}
		}
	}

