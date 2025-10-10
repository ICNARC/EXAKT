/*******************************************************************************
Project: EXAKT
Do file for: Supplementary Figure 7 - bias-SaO2-ITA heatmap
*******************************************************************************/

* import data
use EXAKT${ExtractDate}_postregression, clear

* store knot positions for recreating splines in synthetic data points (not required if running do 3 first)
* derive splines for ITA, SaO2 and HB
mkspline t__ = ITA, cubic nk(4)
mat tk = r(knots) //store knot positions for graphing
drop t__*
mkspline s__ = safrac, cubic nk(4)
mat sk = r(knots) //store knot positions for graphing
drop s__*
mkspline h__ = HB, cubic nk(4)
mat hk = r(knots) //store knot positions for graphing
drop h__*

* prepare data for visual axis
	
	*store percentiles of ITA as limits for plotting
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

	* expand to include 5 oximeters
	g byte n = 1
	replace n = _n
	expand 5
	bysort n: g long o = _n
	lab val o o

	rename ITAint ITA
	//collapse (mean) b_* rmsd_* arms_*, by(o ITA RGB ITAstart ITAend)
	set scheme qqr
	//g y_bias = -11 //y position of visual axis for bias plot
	g y_arms=-2 //y position of visual axis for precision and ARMS plots

	egen group = group(o)
	
	tempfile vis
	save `vis'

********************* prepare data for bias-SaO2-ITA heatmap *******************
clear
loc tens 1
set obs 41
g safrac = .84 + (_n-1)*.16/40
mkspline s = safrac, cubic k(`=sk[1,1]' `=sk[1,2]' `=sk[1,3]' `=sk[1,4]')
expand 51
bysort safrac: g ITA = -72 + (_n-1)*133/50
mkspline t = ITA, cubic k(`=tk[1,1]' `=tk[1,2]' `=tk[1,3]' `=tk[1,4]')
expand 5 
bys safrac ITA: g o =_n
g HB = 101
mkspline h = HB, cubic k(`=hk[1,1]' `=hk[1,2]' `=hk[1,3]' `=hk[1,4]')
g pid = 1
g SiteNumber = 1
estimates use fracreg
predict sp_pr
g bias = sp_pr - safrac
estimates use precision
predict rmse
replace rmse = sqrt(rmse)
estimates use mse 
predict arms
replace arms = sqrt(arms)
foreach v of varlist safrac bias rmse arms {
	replace `v' = `v'*100
	//replace `v' = 84 if `v' < 84
}
labe var rmse "RMSE"
lab var arms "ARMS"
 lab def o 1 "A" 2 "B" 3 "C" 4 "D" 5 "E", modify
 lab val o o
 
append using `vis', gen(source)
lab def source 0 "heatmap" 1 "visualaxis"
lab val source source

replace rmse = 7.999 if rmse >= 8 & !mi(rmse)
replace arms = 7.999 if arms >= 8 & !mi(arms)

* plot bias heatmap
colorpalette twilight shifted, n(21) nograph
return li
#delimit ;
twoway contour bias safrac ITA if source==0, heatmap ccuts(-7.5(.75)7.5) ccolor(`r(p)')
	by(o, note("") col(6) clegend(on at(6)) subti("Bias (%)", col("117 116 119") size(medsmall)))
	ztitle("") zlabel(-7.5 0 "  0    " 7.5 "+7.5", gmax labsize(small)) zsca(r(-7.5 7.5))
	yti(" ", size(medsmall)) ylab(84(4)100, angle(horizontal) labsize(medsmall))
	subti("",bc(none)) /*aspect(1)*/
	plotregion(margin(0 0 0 0))
	xscale(noline reverse) xlabel(none) xtitle("") /*xsize(8) ysize(5.02)*/
	xsize(8) ysize(3) plotregion(margin(l=0 b=0 r=0)) graphregion(margin(0 0 0 0))
	name("bias",replace) nodraw
; #delimit cr

* plot bias heatmap - high res
colorpalette twilight shifted, n(401) nograph
return li
#delimit ;
twoway contour bias safrac ITA if source==0, heatmap ccuts(-7.5(.0375)7.5) ccolor(`r(p)')
	by(o, note("") col(6) clegend(on at(6)) subti("Bias (%)", col("117 116 119") size(medsmall)))
	ztitle("") zlabel(-7.5 0 "  0    " 7.5 "+7.5", gmax labsize(small)) zsca(r(-7.5 7.5))
	yti(" ", size(medsmall)) ylab(84(4)100, angle(horizontal) labsize(medsmall))
	subti("",bc(none)) /*aspect(1)*/
	plotregion(margin(0 0 0 0))
	xscale(noline reverse) xlabel(none) xtitle("") /*xsize(8) ysize(5.02)*/
	xsize(8) ysize(3) plotregion(margin(l=0 b=0 r=0)) graphregion(margin(0 0 0 0))
	name("biashigh",replace) nodraw
; #delimit cr

* plot precision heatmap
colorpalette twilight shifted, n(21) nograph
return li
#delimit ;
twoway contour rmse safrac ITA if source==0, heatmap ccuts(0(.4)8) ccolor(`r(p)')
	by(o, note("") col(6) clegend(on at(6)) subti("Precision (%)", col("117 116 119") size(medsmall)))
	ztitle("") zlabel(0 "  0    " 4 "  4" 8 "≥8", gmax labsize(small)) zsca(r(0 8))
	yti("SaO{subscript:2}, %", size(medsmall)) ylab(84(4)100, angle(horizontal) labsize(medsmall))
	subti("",bc(none)) /*aspect(1)*/
	plotregion(margin(0 0 0 0))
	xscale(noline reverse) xlabel(none) xtitle("") /*xsize(8) ysize(5.02)*/
	xsize(8) ysize(3) plotregion(margin(l=0 b=0 r=0)) graphregion(margin(0 0 0 0))
	name("precision",replace) nodraw
; #delimit cr

* plot precision heatmap
colorpalette twilight shifted, n(401) nograph
return li
#delimit ;
twoway contour rmse safrac ITA if source==0, heatmap ccuts(0(.02)8) ccolor(`r(p)')
	by(o, note("") col(6) clegend(on at(6)) subti("Precision (%)", col("117 116 119") size(medsmall)))
	ztitle("") zlabel(0 "  0    " 4 "  4" 8 "≥8", gmax labsize(small)) zsca(r(0 8))
	yti("SaO{subscript:2}, %", size(medsmall)) ylab(84(4)100, angle(horizontal) labsize(medsmall))
	subti("",bc(none)) /*aspect(1)*/
	plotregion(margin(0 0 0 0))
	xscale(noline reverse) xlabel(none) xtitle("") /*xsize(8) ysize(5.02)*/
	xsize(8) ysize(3) plotregion(margin(l=0 b=0 r=0)) graphregion(margin(0 0 0 0))
	name("precisionhigh",replace) nodraw
; #delimit cr

* plot arms heatmap
colorpalette twilight shifted, n(21) nograph
return li
#delimit ;
twoway contour arms safrac ITA if source==0, heatmap ccuts(0(.4)8) ccolor(`r(p)')
	by(o, note("") col(6) clegend(on at(6)) subti("Accuracy (%)", col("117 116 119") size(medsmall)))
	ztitle("") zlabel(0 "  0    " 4 "  4" 8 "≥8", gmax labsize(small)) zsca(r(0 8))
	yti(" ", size(medsmall)) ylab(84(4)100, angle(horizontal) labsize(medsmall))
	subti("",bc(none)) /*aspect(1)*/
	plotregion(margin(0 0 0 0))
	xscale(noline reverse) xlabel(none) xtitle("") /*xsize(8) ysize(5.02)*/
	xsize(8) ysize(3) plotregion(margin(l=0 b=0 r=0)) graphregion(margin(0 0 0 0))
	name("arms",replace) nodraw
; #delimit cr

* plot arms heatmap
colorpalette twilight shifted, n(401) nograph
return li
#delimit ;
twoway contour arms safrac ITA if source==0, heatmap ccuts(0(.02)8) ccolor(`r(p)')
	by(o, note("") col(6) clegend(on at(6)) subti("Accuracy (%)", col("117 116 119") size(medsmall)))
	ztitle("") zlabel(0 "  0    " 4 "  4" 8 "≥8", gmax labsize(small)) zsca(r(0 8))
	yti(" ", size(medsmall)) ylab(84(4)100, angle(horizontal) labsize(medsmall))
	subti("",bc(none)) /*aspect(1)*/
	plotregion(margin(0 0 0 0))
	xscale(noline reverse) xlabel(none) xtitle("") /*xsize(8) ysize(5.02)*/
	xsize(8) ysize(3) plotregion(margin(l=0 b=0 r=0)) graphregion(margin(0 0 0 0))
	name("armshigh",replace) nodraw
; #delimit cr

************************** X axis labelling *************************************
* plot x axis labels and title
g byte zero = 0

#delimit ;
twoway 
	(line zero ITA, lw(none))
	,
	by(o, note("") col(5) legend(off) plotregion(margin(l+14 r+26)))
	subti("",bc(none))
	yti("") ylab(none) ysc(noline)
	xti("Individual Typology Angle (ITA), °" "Indicative skin tone:")
	xlab(-60(30)60) xscale(reverse)
	legend(off) plotregion(margin(l=0 b=0 r=0 t=0)) graphregion(margin(t=0 b=0)) fysize(8)
	name(xaxis, replace) nodraw
; #delimit cr

* plot ITA visual axis
cap g yvis = -5
cap replace yvis = -5

sort o ITAstart
count if o==1 & !mi(ITAstart)
local colorlist ""
forval i = 1/`=r(N)'{
	local colorlist `"`colorlist' "`=RGB[`i']'""'
}
di `"`colorlist'"'
sum yvis, meanonly
#delimit ;
twoway 
	(rbar ITAstart ITAend yvis if !mi(ITAstart), horizontal colorvar(ITA) colordiscrete colorlist(`colorlist') barw(4.6) bstyle(none) lp(blank) lw(none) lc(none))
	,
	by(o, note("") col(5) legend(off) plotregion(margin(l+14 r+26)))
	subti("",bc(none))
	yti("") ylab(none) /*ylab(`=r(mean)' "                    ", tl(0))*/
	xti("")/*xti("Skin tone (ITA range 61° to −72°)") */
	xlab(-50 "Dark" -10 "Brown" 19 "Tan" 34.5 "Intermediate" 48 "Light" 60 "Very light", tl(0) angle(70))	
	/*legend(order(4 "Target" 2 "Point estimate" 1 "95% C.I.") region(lp(blank)) row(1) pos(6)) 
	fysize(120) */
	legend(off) plotregion(margin(l=0 b=0 r=0)) graphregion(margin(t=0 b=0)) xscale(noline reverse) yscale(noline)
	name(visualaxis, replace) nodraw
; #delimit cr

* plot oximeter labels
cap g byte zero = 0
#delimit ;
twoway 
	(line zero ITA, lw(none))
	,
	by(o, note("") col(5) legend(off) plotregion(margin(l+10 r+20)))
	subti(,bc(none) col("117 116 119"))
	yti("") ylab(none) ysc(noline)
	xti("")	xlab(none) xsc(noline)
	fysize(5) legend(off) plotregion(margin(l=0 b=0 r=0))
	name(oximeters, replace) nodraw
; #delimit cr

graph combine xaxis visualaxis, col(1) graphregion(col(white)) xcommon imargin(zero) graphregion(margin(l=0 r=20 t=0 b=0)) name(combinedxaxis, replace) nodraw fysize(22)

* combine
graph combine oximeters bias precision arms combinedxaxis, col(1) graphregion(col(white)) xcommon imargin(small) graphregion(margin(l=0 r=0)) xsize(26) ysize(20) 
graph export "${OutputDir}\\Joint heatmap.png", replace 	// warning: vector files are huge if resolution is high
graph export "${OutputDir}\\Joint heatmap.svg", replace 
graph export "${OutputDir}\\Joint heatmap.pdf", replace 

graph combine oximeters biashigh precisionhigh armshigh combinedxaxis, col(1) graphregion(col(white)) xcommon imargin(small) graphregion(margin(l=0 r=0)) xsize(26) ysize(20) 
graph export "${OutputDir}\\Joint heatmap (high res).png", replace 	// warning: vector files are huge if resolution is high
//graph export "${OutputDir}\\Joint heatmap (high res).svg", replace 
graph export "${OutputDir}\\Joint heatmap (high res).pdf", replace 
