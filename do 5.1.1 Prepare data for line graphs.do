/*******************************************************************************
Project: EXAKT
Do file for: Prepare data for plotting line graphs
*******************************************************************************/

* config
cd "S:\Stats\7. Confidential\Trials\UK-ROX\EXAKT"
version 17
set varabbrev off
set more off

* import data
use EXAKT${ExtractDate}_postregression if !mi(safrac, spfrac, HB, ITA, o), clear

* store median HB
sum HB, detail
loc HBp50 = r(p50)

*store covariates at levels of saO2 of interest: 88, 92, 96
preserve
	collapse (first) s? (median) h? if inlist(safrac, float(.88), float(0.92), float(0.94), float(0.96)), by(safrac)
	g byte n = 1
	tempfile covariates
	save `covariates'
restore

*store limits of ITA for plotting
sum ITA if RepeatNumber==1 & oximeter_n==1 & ITA>-89, detail
loca ITAstart = round(r(min)) 
loca ITAend = round(r(max)) 

* store median l-a-b & RGB values for each level of ITA, for use in visual axis
g int ITAint = round(ITA)
keep if RepeatNumber==1 & oximeter_n==1 & inrange(ITA,`ITAstart',`ITAend')
egen Amed = rowmedian(AValue_1 AValue_2 AValue_3 AValue_4)
mkspline ITAsp = ITA, cubic nk(3)
foreach v in A B L{
	reg `v'med ITAsp?
	predict `v'med_pr
}
collapse (median) Amed_pr Bmed_pr Lmed_pr t?, by(ITAint)
lab2rgb Lmed_pr Amed_pr Bmed_pr, string
sort ITAint
g ITAstart = cond(_n==1, ITAint-0.5, ITAint[_n-1] + (ITAint - ITAint[_n-1])/2)
g ITAend = cond(_n==_N, ITAint+0.5, ITAstart[_n+1])

* cross-join observed distribution of safrac to range of ITA for plotting
g byte n = 1
joinby n using `covariates'

* expand to include 5 oximeters
replace n = _n
expand 5
bysort n: g long o = _n
lab val o o

* predict bias
estimates use fracreg
predict sp_pr
predict sp_xb, xb
predict sp_se, stdp	
g sp_lb = normal(sp_xb - invnormal(0.975)*sp_se)
g sp_ub = normal(sp_xb + invnormal(0.975)*sp_se)
foreach v of varlist safrac sp_pr sp_ub sp_lb{
	replace `v' = `v'*100
}
g b_pr = sp_pr - safrac
lab var b_pr "Bias"
g b_lb = sp_lb - safrac
lab var b_lb "Bias (lower bound)"
g b_ub = sp_ub - safrac
lab var b_lb "Bias (upper bound)"

* predict MSD and precision
estimates use precision
predict msd_pr, cm
predict msd_xb, xb
predict msd_se, stdp	
g msd_lb = normal(msd_xb - invnormal(0.975)*msd_se)
g msd_ub = normal(msd_xb + invnormal(0.975)*msd_se)
foreach v in _pr _ub _lb {
	g rmsd`v' = sqrt(msd`v')*100
}
lab var rmsd_pr "Root mean squared deviation"
lab var rmsd_lb "RMSD (lower bound)"
lab var rmsd_lb "RMSD (upper bound)"
sum rmsd*

* predict MSE and ARMS
estimates use mse
predict mse_pr
predict mse_xb, xb
predict mse_se, stdp	
g mse_lb = normal(mse_xb - invnormal(0.975)*mse_se)
g mse_ub = normal(mse_xb + invnormal(0.975)*mse_se)
foreach v in _pr _ub _lb{
	g arms`v' = sqrt(mse`v')*100
}
lab var arms_pr "Accuracy root mean square"
lab var arms_lb "ARMS (lower bound)"
lab var arms_lb "ARMS (upper bound)"
sum arms*

rename ITAint ITA
//collapse (mean) b_* rmsd_* arms_*, by(o ITA RGB ITAstart ITAend)
set scheme qqr
//g y_bias = -11 //y position of visual axis for bias plot
g y_arms=-7.5 //y position of visual axis for precision and ARMS plots

//egen group = group(o safrac)
save DataForMeasurmentAccuracyPlots, replace

****************************** Diagnostic accuracy plots ***************************
* import data
use EXAKT${ExtractDate}_postregression if !mi(safrac, spfrac, HB, ITA, o), clear

* store subdistrubtions of SaO2 among cases and non-cases for sensitivity and specificty
// using random sample of 100 to speed up predictions
preserve
	keep if safrac<=float(.92)
	keep s? SiteNumber pid sp??orless
	g byte n = 1
	g double rand = runiform()
	sort rand
	drop rand
	keep if _n<100
	tempfile sa_cases
	save `sa_cases'
	//save sa_cases, replace
restore, preserve
	keep if safrac>float(.92) & !mi(safrac)
	keep s? SiteNumber pid sp??orless
	g byte n = 1
	g double rand = runiform()
	sort rand
	drop rand
	keep if _n<100
	tempfile sa_noncases
	save `sa_noncases'
	//save sa_noncases, replace
restore, preserve
	keep if safrac<float(.88) & !mi(safrac)
	keep s? SiteNumber pid sp??orless
	g byte n = 1
	g double rand = runiform()
	sort rand
	drop rand
	keep if _n<100
	tempfile sa_hypox
	save `sa_hypox'
	//save sa_hypox, replace
restore

*store median HB values
preserve
	collapse (median) h?
	g byte n = 1
	tempfile HB
	save `HB'
restore

* store percentiles of ITA as limits for plotting
sum ITA if RepeatNumber==1 & oximeter_n==1 & ITA>-89, detail
loca ITAstart = round(r(min)) 
loca ITAend = round(r(max)) 

* store median l-a-b & RGB values for each level of ITA, for use in visual axis
g int ITAint = round(ITA)
keep if RepeatNumber==1 & oximeter_n==1 & inrange(ITA,`ITAstart',`ITAend')
egen Amed = rowmedian(AValue_1 AValue_2 AValue_3 AValue_4)
mkspline ITAsp = ITA, cubic nk(3)
foreach v in A B L{
	reg `v'med ITAsp?
	predict `v'med_pr
}
collapse (median) Amed_pr Bmed_pr Lmed_pr t?, by(ITAint)
lab2rgb Lmed_pr Amed_pr Bmed_pr, string
sort ITAint
g ITAstart = cond(_n==1, ITAint-0.5, ITAint[_n-1] + (ITAint - ITAint[_n-1])/2)
g ITAend = cond(_n==_N, ITAint+0.5, ITAstart[_n+1])
rename ITAint ITA

* add HB
g byte n = 1
merge m:1 n using `HB', nogen

* expand to include 5 oximeters
replace n = _n
expand 5
bysort n: g long o = _n
lab val o o

* recreate dummies and interactions
tabulate o, gen(o)
forval o= 1/5{
	forval t = 1/3{
		g o`o't`t' = cond(o==`o',t`t',0)
		lab var o`o't`t' "Oximeter `=char(`o' + 64)' interaction with ITA spline `t'"
	}
}

* predict auroc
estimates use rocreg
predict auc, auc ci(auc) //warning: takes about 30sec/1000 observations
foreach v of varlist auc auc_l auc_u{
	replace `v' = `v'*100
}
replace auc_u = 100 if auc_u>100 & !mi(auc_u)
replace auc_l = 50 if auc_l<50 & !mi(auc_l)


* predict sensitivity and specificity 
* cross join to observed subdistribution of SaO2 among cases and noncases
cap replace n = 1
cap gen n=1

foreach group in cases noncases hypox{ 
	joinby n using `sa_`group''
	foreach level in sp92orless sp94orless{
		estimates use `level'
		//predict `level'_pr_`group', pr
		predict `level'_xb_`group', xb
		g `level'_pr_`group' = invlogit(`level'_xb_`group')
		predict `level'_se_`group', stdp	
		//g `level'_pr_`group' = invlogit(`level'_xb_`group')
		g `level'_lb_`group' = invlogit(`level'_xb_`group' - invnormal(0.975)* `level'_se_`group')
		g `level'_ub_`group' = invlogit(`level'_xb_`group' + invnormal(0.975)* `level'_se_`group')
		foreach v of varlist `level'_pr_`group' `level'_ub_`group' `level'_lb_`group'{
			replace `v' = `v'*100
			g oneminus_`v' = 100 - `v'
		}
	}		
	collapse (mean) *_pr_* *_ub_* *_lb_* auc*, by(o ITA h1 h2 h3 t1 t2 t3 ITAstart ITAend RGB n)
}
foreach v of varlist *_noncases *_hypox{
	replace `v' = 100 - `v' // !!NB these are now reverse scaled, so probability of test negative
}
sort o ITA
save DataForDiagnosticAccuracyPlots, replace
