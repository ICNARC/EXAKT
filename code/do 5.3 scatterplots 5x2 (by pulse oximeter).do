/*******************************************************************************
Project: EXAKT
Do file for: Figure 2 (scatterplots)
*******************************************************************************/

*config
version 17
set varabbrev off
set more off
set seed 24092222

*import & transform data (copied from do 3 to save rerunning all regressions)
	* import & transform data
	use EXAKT$ExtractDate, clear
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
	
	g byte TestNegative = spfrac >= float(0.92) /*& safrac < float(0.88)*/ if !mi(spfrac, spfrac)
	lab var TestNegative "SpO2 >= 92%"
	g byte TestPositive = spfrac < float(0.88) /*& safrac >= float(0.92)*/ if !mi(safrac, spfrac)
	lab var TestPositive "SpO2 < 88%"
	
	mkspline t = ITA, cubic nk(4)
	mat tk = r(knots) //store knot positions for graphing
	mkspline s = safrac, cubic nk(4)
	mat sk = r(knots) //store knot positions for graphing
	mkspline h = HB, cubic nk(4)
	mat hk = r(knots) //store knot positions for graphing
	
*collect median HB
sum HB, detail
loc med = r(p50)
forval i=1/3{
	sum h`i' if HB==`med'
	loc h`i' = r(mean)
}

* collect median ITA within skin tone categories
preserve
	collapse (median) t? /*, by(skincat)*/ 
	g byte skincat=1
	tempfile ITAs
	save `ITAs'
restore

* derive jitter
foreach v in sp sa{
	g `v'jitter = `v'frac + runiform()*.01-.005
	replace `v'jitter = 1 if `v'jitter>1 & !mi(`v'jitter)
}

* derive error
g e = spjitter - sajitter

* store points for plotting
recode skincat 6=5
keep e spjitter sajitter skincat o
tempfile points
save `points'

* setup data for plotting models
clear
set obs 101
g safrac = .8 + .2*(101-_n)/100
mkspline s = safrac, cubic k(`=sk[1,1]' `=sk[1,2]' `=sk[1,3]' `=sk[1,4]')
forval i=1/3{
	//g t`i' = `t`i''
	g h`i' = `h`i''
}
g id = _n
expand 5
bysort id: g byte o = _n
//expand 5
//bysort id o: g byte skincat=_n
g byte skincat=1
merge m:1 skincat using `ITAs'


* predict Sp & bias
estimates use fracreg
predict sp_pr
predict sp_xb, xb
predict sp_se, stdp	
g sp_lb = normal(sp_xb - invnormal(0.975)*sp_se)
g sp_ub = normal(sp_xb + invnormal(0.975)*sp_se)
g b_pr = sp_pr - safrac
lab var b_pr "Bias"
g b_lb = sp_lb - safrac
lab var b_lb "Bias (lower bound)"
g b_ub = sp_ub - safrac
lab var b_lb "Bias (upper bound)" 

* create grey region for error plot
g greymax = .1 // graph will be over safrac range (80, 100) so maximum error & top of y axis is 20
g greymin = 1-safrac if safrac>=float(.9)

* limits of occult hypoxaemia and false alarms (SpO2)
g spmax = 1
g spmin = 0
g sp92 = .92
g sp88 = .88

* limits of occult hypoxaemia and false alarms (error)
g emin = -.1
g oh = .92 - safrac if safrac<=.88

* add points
append using `points'
sort o skincat safrac sajitter

recode skincat 1=5 2=4 4=2 5=1
lab def skincatrecode 1 "Light" 2 "Intermediate" 3 "Tan" 4 "Brown" 5 "Dark"
lab val skincat skincatrecode 
lab val o o
sort o skincat safrac

* restrict confidence intervals to plotted area
replace sp_lb= .8 if sp_lb <=.8
replace b_ub= .1 if b_ub >= .1 & !mi(b_ub)
replace sp_pr = . if sp_pr <.8
* plot

	* plot SpO2-SaO2
	#delimit ;
	twoway 
		(scatter spjitter sajitter, msize(*.2) pstyle(p3))
		(function y=x, range(.80 1.00) lc(eltgreen) lw(*2) lp(dash))
		(rarea sp_ub sp_lb safrac, pstyle(p1) col(%40) lw(none))
		(line sp_pr safrac, pstyle(p1) lw(*2))
		if safrac>=.8 & sajitter>=.8 & spjitter>=.8, scheme(qqr)
		by(o, col(5) note("") iscale() imargin(+5) leg(off)) subti(, size(medium) bc(none) margin(b+2))
		yti("SpO{subscript:2}, %", margin())
		xti("")
		ylab(/*.6 "60" .7 "70" */.8 "80" .9 "90" 1 "100", grid glc(white) )
		ymtick(0.8(0.05)1, grid glc(white))
		/*xlab(.80 "80" .9 "90" 1 "100", grid glc(white))*/
		xlab(none)
		xmtick(.80 (0.05)1, grid glc(white) tl(0)) xsc(noline)
		aspect(1) plotregion(margin(0 0 0 0) col(gs14))
		/*leg(order(2 "Target" 1 "Data point" 4 "Adjusted mean" 3 "95% CI") pos(6) region(lc(none)) span)*/
		name(SpO2SaO2_byoximeter, replace) nodraw
	; #delimit cr

	* plot error-SaO2
	#delimit ;
	twoway 
		(pci .10 .90 .10 1.00, lc(white) lp(dash) lw(*1.5))
		(pci .10 1.00 0 1.00, lc(white) lp(dash) lw(*1.5))
		(pci .10 .80 0 1.00, lc(gs14))
		(pci 0 1.00 -.10 1.00, lc(gs14))
		(rarea greymax greymin safrac, col(white))
		/*(scatter e sajitter if inrange(sajitter,float(.8),float(.88)) & spjitter>=float(.92), msize(1) mlcol(pink) mfcol(none) mlw(*.5))
		(scatter e sajitter if sajitter>=float(.92) & spjitter <= float(0.88) & e>=-.2, msize(1) mlcol(purple) mfcol(none) mlw(*.5))*/
		(scatter e sajitter if sajitter>=.8 & inrange(e,-.1,.1), msize(*.2) pstyle(p3))
		(function y=0, range(.80 1.00) lc(eltgreen) lw(*2) lp(dash))
		(rarea b_ub b_lb safrac, pstyle(p1) col(%40) lw(none))
		(line b_pr safrac, pstyle(p1) lw(*2))
		if safrac>=.8, scheme(qqr)
		by(o, col(5) note("") iscale() imargin(+5) leg(off)) subti("")
		yti("Error (SpO{subscript:2} − SaO{subscript:2}), %", margin())
		xti("SaO{subscript:2}, %", margin(t+2))
		ylab(-.1 "−10" 0 "0" .1 "+10" , grid glc(white))
		ymtick(-.1(0.05).1, grid glc(white))
		/*ylab(-.2 "-20" -.1 "-10" 0 "0" .1 "+10" .2 "+20" , grid glc(white))
		ymtick(-.2(0.05).2, grid glc(white))*/
		xlab(.80 "80" .9 "90" 1 "100", grid glc(white))
		xmtick(.80 (0.05)1, grid glc(white))
		/*text(.075 .975 "Impossible", col(gs10) size(vsmall) angle(-45))*/
		aspect(1) plotregion(margin(0 0 0 0) col(gs14))
		subti(, size(medium) bc(none) margin(b+2))
		leg(off) /*leg(order(9 "Target" 11 "Adjusted mean" 10 "95% CI" 8 "Data point" 6 "Occult hypoxaemia" 7 "False alarm") colfirst pos(6)  region(lc(none)) span symxsize(*.5) symysize(*.5) size(vsmall))*/
		fysize() name(bias_byoximeter, replace) nodraw
	; #delimit cr
	
	graph combine SpO2SaO2_byoximeter bias_byoximeter, col(1) graphregion(col(white)) xcommon imargin(small) graphregion(margin(l=0 r=0)) xsize(8) ysize(4) iscale(*1.5)
	graph export "${OutputDir}\Scatter plots for main paper.svg", replace
	graph export "${OutputDir}\Scatter plots for main paper.pdf", replace




