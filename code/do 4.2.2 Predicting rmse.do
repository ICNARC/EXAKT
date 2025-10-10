/*******************************************************************************
Project: EXAKT
Do file for: Adjusted precision - overall
*******************************************************************************/

* Import only data for modelling
use EXAKT${ExtractDate}_postregression if !mi(spfrac, safrac, ITA, HB), clear
recode skincat (6=5)

* Reorder just to make life easier in outputting results
g skincat_rec = 6-skincat 
drop skincat 
ren skincat_rec skincat

* Getting median ITAs for each skin tone
forval i = 1/3{
	forval j = 1/5{
		sum t`i' if skincat == `j',detail
		global t`i'_`j' = r(p50)		
	}
}

* define bootstrap program
cap prog drop pr_rmse
prog pr_rmse, rclass
	
	* RMSE
	fracreg probit SquaredDeviation t? s? c.t1#c.s1 c.t1#c.s2 c.t1#c.s3 c.t2#c.s1 c.t3#c.s1 ///
		i.o i.o#c.t1 i.o#c.t2 i.o#c.t3 i.o#c.s1 i.o#c.s2 i.o#c.s3 ///
		h?, vce(cluster pid)	
	
	* estimate limits
	forval i = 1/5 {
		margins, at(t1=${t1_`i'} t2=${t2_`i'} t3=${t3_`i'}) over(i.o)
		* by pulse oximeter
		forval j = 1/5{
			loc o`j'_s`i' = r(table)[1,`j']
		}
		* overall
		margins, at(t1=${t1_`i'} t2=${t2_`i'} t3=${t3_`i'})
		loc o6_s`i' = r(table)[1,1]
	}
	
	* Predict over oximeters over all ITAs
	margins, over(i.o)
	forval i = 1/5{
		loc o`i'_s6 = r(table)[1,`i']
	}
	* Predict over all
	margins 
	loc o6_s6 = r(table)[1,1]
	
	* Return all the values in scalars for bootstrapping
	forval i = 1/6 {
		forval j = 1/6 {
			return scalar rmse_o`i'_s`j' = 100*sqrt(`o`i'_s`j'')
		}
	}
	
	*calculate difference for range
	forval i = 1/ 6 {
		return scalar rmse_range`i' = 100*(sqrt(`o`i'_s5') - sqrt(`o`i'_s1'))
	}	
	

end

* run estimation
bootstrap r(rmse_o1_s1) r(rmse_o1_s2) r(rmse_o1_s3) r(rmse_o1_s4) r(rmse_o1_s5) r(rmse_o1_s6) r(rmse_range1) ///
		  r(rmse_o2_s1) r(rmse_o2_s2) r(rmse_o2_s3) r(rmse_o2_s4) r(rmse_o2_s5) r(rmse_o2_s6) r(rmse_range2) ///
		  r(rmse_o3_s1) r(rmse_o3_s2) r(rmse_o3_s3) r(rmse_o3_s4) r(rmse_o3_s5) r(rmse_o3_s6) r(rmse_range3) ///
		  r(rmse_o4_s1) r(rmse_o4_s2) r(rmse_o4_s3) r(rmse_o4_s4) r(rmse_o4_s5) r(rmse_o4_s6) r(rmse_range4) ///
		  r(rmse_o5_s1) r(rmse_o5_s2) r(rmse_o5_s3) r(rmse_o5_s4) r(rmse_o5_s5) r(rmse_o5_s6) r(rmse_range5) ///
		  r(rmse_o6_s1) r(rmse_o6_s2) r(rmse_o6_s3) r(rmse_o6_s4) r(rmse_o6_s5) r(rmse_o6_s6) r(rmse_range6) ///
		  , reps($bsreps): pr_rmse 


putexcel set "${OutputDir}\\Measurement accuracy - RMSE", modify sheet("Adjusted")
excel
forval i = 1/6 {
	forval j = 1/7 {
		local matrow = (`i'-1)*7 + `j' // Matrix row to use
		local row = `j' + 1 // Row of output excel to put to 
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
