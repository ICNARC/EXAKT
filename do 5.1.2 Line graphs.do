/*******************************************************************************
Project: EXAKT
Do file for: Line graphs - figures 3 and 4 and supplementary figures 4-6
*******************************************************************************/

set scheme qqr
global ylabsize small

use DataForMeasurmentAccuracyPlots, clear

************ measurement accuracy plots for each for each level of safrac ******
foreach s in 88 92 94 96 {
	* plot bias-ITA
	#delimit ;
	twoway 
		(rarea b_lb b_ub ITA, pstyl(p1) col(%30) lw(none))
		(line b_pr ITA, pstyl(p1))
		if safrac == float(`s'),
		by(o, note("") col(5) legend(off) subti("Bias at SaO{subscript:2} = `s'% (%)", size(small) col("117 116 119")))
		subti("",bc(none))
		yti("")  ylab(-7.5 "Under −7.5" -2.5 "−2.5" 0 "Perfect      " 2.5 "+2.5" 7.5 "Over   +7.5", gmax gmin labsize($ylabsize)) yline(0, lc(eltgreen) lw(*2) lp(dash))
		xti("") xlab(none) 
		fysize(50) fxsize(160) leg(off) plotregion(margin(l=0 b=0 r=0 t=0)) xscale(noline reverse)
		name(bias_`s', replace) nodraw
	; #delimit cr
	
	* plot Precision-ITA
	#delimit ;
	twoway 
		(rarea rmsd_lb rmsd_ub ITA, pstyl(p1) col(%30) lw(none))
		(line rmsd_pr ITA, pstyl(p1))
		if safrac == float(`s'),
		by(o, note("") col(5) legend(off) subti("Precision at SaO{subscript:2} = `s'% (%)", size(small) col("117 116 119")))
		subti("",bc(none))
		yti("") ylab(0 "Perfect    0" 5 10 15 "Worse   15", gmax labsize($ylabsize)) yline(0, lc(eltgreen) lw(*2) lp(dash))
		xti("") xlab(none) 
		fysize(50) fxsize(160) legend(off) plotregion(margin(l=0 b=0 r=0 t=0)) xscale(noline reverse)
		name(precision_`s', replace) nodraw
	; #delimit cr
	
	* plot ARMS-ITA
	#delimit ;
	twoway 
		(rarea arms_lb arms_ub ITA, pstyl(p1) col(%30) lw(none))
		(line arms_pr ITA, pstyl(p1))
		if safrac == float(`s'),
		by(o, note("") col(5) legend(off)  subti("Accuracy at SaO{subscript:2} = `s'% (%)", size(small) col("117 116 119")))
		subti("",bc(none))
		yti("")  ylab(0 "Perfect    0" 5 10 15 "Worse   15", gmax labsize($ylabsize)) yline(0, lc(eltgreen) lw(*2) lp(dash))
		xti("") xlab(none)
		fysize(50) fxsize(160)  legend(off)  plotregion(margin(l=0 b=0 r=0 t=0)) xscale(noline reverse)
		name(arms_`s', replace) nodraw
	; #delimit cr
}

****************************** Diagnostic accuracy plots ***************************
use DataForDiagnosticAccuracyPlots, clear

* plot AUC-ITA
foreach s in 92 /*94*/ {
	#delimit ;
	twoway 
		(rarea auc_l auc_u ITA, pstyl(p1) col(%30) lw(none))
		(line auc ITA, pstyl(p1)),
		by(o, note("") col(5) legend(off) subti("Area under ROC curve for SaO{subscript:2} ≤ 92% (%)", col("117 116 119") size(small)))
		subti("",bc(none))
		yti("")  ylab(50 "Worst     50" 60 70 80 90 100 "Perfect 100", gmax labsize($ylabsize)) yline(100, lc(eltgreen) lw(*2) lp(dash))
		xti("") xlab(none) /*xlab(-50 "Dark" -10 "Brown" 19 "Tan" 34.5 "Intermediate" 48 "Light" 60 "Very light", tl(0) angle(70))*/
		fysize(50) fxsize(160) leg(off) plotregion(margin(l=0 b=0 r=0 t=0)) xscale(noline reverse)
		name(auc_`s', replace) nodraw
	; #delimit cr
}

* plot sensitivity and specificity & hypoxaemia

foreach group in cases noncases hypox { 
	foreach scale in "" "oneminus_"{
		foreach s in 92 94{
			if "`group'" == "noncases" & "`scale'" == ""{
				loc yti `"Specificity (% of SaO{subscript:2} > 92% with SpO{subscript:2} > `s'%)"'
				loc perfect 100
				loc ylab `"0 "Worst       0" 25 50 75 100 "Perfect 100""'
			}
			if "`group'" == "noncases" & "`scale'" == "oneminus_"{
				loc yti `"False positive rate (% of SaO{subscript:2} > 92% with SpO{subscript:2} ≤ `s'%)"'
				loc perfect 0
				loc ylab `"0 "Perfect     0" 25 50 75 100 "Worst   100""'
			}
			if "`group'" == "hypox" & "`scale'" == ""{
				loc yti `"Occult hypoxaemia (% of SaO{subscript:2} < 88% with SpO{subscript:2} > 92%)"'
				loc perfect 0
				loc ylab `"0 "Perfect     0" 25 50 75 100 "Worst   100""'
			}
			if "`group'" == "hypox"  & "`scale'" == "oneminus_"{
				loc yti `"one minus occult hypoxaemia (dont use)"'
				loc perfect 100
				loc ylab `"0 "Perfect     0" 25 50 75 100 "Worst   100""'
			}
			if "`group'" == "cases"  & "`scale'" == ""{
				loc yti `"Sensitivity (% of SaO{subscript:2} ≤ 92% with SpO{subscript:2} ≤ `s'%)"'
				loc perfect 100
				loc ylab `"0 "Worst       0" 25 50 75 100 "Perfect 100""'
			}
			if "`group'" == "cases"  & "`scale'" == "oneminus_"{
				loc yti `"False negative rate (% of SaO{subscript:2} ≤ 92% with SpO{subscript:2} > `s'%)"'
				loc perfect 0
				loc ylab `"0 "Perfect     0" 25 50 75 100 "Worst   100""'
			}
		
		#delimit ;
		twoway 
			(rarea `scale'sp`s'orless_lb_`group' `scale'sp`s'orless_ub_`group' ITA, pstyl(p1) col(%30) lw(none))
			(line `scale'sp`s'orless_pr_`group' ITA, pstyl(p1))
			,
			by(o, note("") col(5) legend(off) subti("`yti'", col("117 116 119") size(small)))
			subti("",bc(none))
			yti("") ylab(`ylab', gmax gmin labsize($ylabsize))	yline(`perfect', lc(eltgreen) lw(*2) lp(dash))
			/*xti("") xlab(-50 "Dark" -10 "Brown" 19 "Tan" 34.5 "Intermediate" 48 "Light" 60 "Very light", tl(0) angle(70))*/
			xti("") xlab(none) xscale(noline reverse)
			fysize(50) fxsize(160) legend(off) plotregion(margin(l=0 b=0 r=0 t=0)) 
			name(`scale'`group'_sp`s'orless, replace) nodraw
		; #delimit cr
		//graph save `group'_`level', replace
		}
	}
}

************************** X axis labelling *************************************
* plot x axis labels and title
cap g byte zero = 0
#delimit ;
twoway 
	(line zero ITA, lw(none))
	,
	by(o, note("") col(5) legend(off) plotregion(margin(l+20)))
	subti("",bc(none))
	yti("") ylab(none) ysc(noline)
	xti("Individual Typology Angle (ITA), °" "Indicative skin tone:")
	xlab(-60(30)60) xscale(reverse)
	fysize(40) /*fxsize(160)*/ legend(off) plotregion(margin(l=0 b=0 r=0 t=0))
	name(xaxis, replace) nodraw
; #delimit cr

* plot ITA visual axis
cap g yvis = -5
cap replace yvis = -5

sort o ITA
count if o==1
local colorlist ""
forval i = 1/`=r(N)'{
	local colorlist `"`colorlist' "`=RGB[`i']'""'
}
sum yvis, meanonly
#delimit ;
twoway 
	(rbar ITAstart ITAend yvis, horizontal colorvar(ITA) colordiscrete colorlist(`colorlist') barw(4.6) bstyle(none) lp(blank) lw(none) lc(none))
	,
	by(o, note("") col(5) legend(off) plotregion(margin(l+20)))
	subti("",bc(none))
	yti("") ylab(none) /*ylab(`=r(mean)' "                    ", tl(0))*/
	xti("")/*xti("Skin tone (ITA range 61° to −72°)") */
	xlab(-50 "Dark" -10 "Brown" 19 "Tan" 34.5 "Intermediate" 48 "Light" 60 "Very light", tl(0) angle(70))	
	/*legend(order(4 "Target" 2 "Point estimate" 1 "95% C.I.") region(lp(blank)) row(1) pos(6)) 
	fysize(120) */
	fysize(70) /*fxsize(160)*/ legend(off) plotregion(margin(l=0 b=0 r=0)) xscale(noline reverse) yscale(noline)
	name(visualaxis, replace) nodraw
; #delimit cr

* plot oximeter labels
cap g byte zero = 0
#delimit ;
twoway 
	(line zero ITA, lw(none))
	,
	by(o, note("") col(5) legend(off) plotregion(margin(l+11)))
	subti(,bc(none) col("117 116 119"))
	yti("") ylab(none) ysc(noline)
	xti("")	xlab(none) xsc(noline)
	fysize(20) fxsize(160) legend(off) plotregion(margin(l=0 b=0 r=0))
	name(oximeters, replace) nodraw
; #delimit cr

graph combine xaxis visualaxis, col(1) graphregion(col(white)) xcommon imargin(zero) graphregion(margin(l=0 r=0 t=0 b=0)) name(combinedxaxis, replace) nodraw fysize(90) fxsize(160)


******************************* Combined figures *******************************

* main figure for paper
graph combine oximeters bias_92 precision_92 arms_92 oneminus_cases_sp92orless oneminus_noncases_sp92orless auc_92 hypox_sp92orless combinedxaxis, col(1) graphregion(col(white)) xcommon imargin(small) graphregion(margin(l=0 r=0)) xsize(20) ysize(26) name(CombinedLines, replace) 
//graph save ${OutputDir}\CombinedLines, replace
graph export ${OutputDir}\CombinedLines.svg, replace
//graph export ${OutputDir}\CombinedLines.emf, replace
graph export ${OutputDir}\CombinedLines.pdf, replace
graph export ${OutputDir}\CombinedLines.png, replace


* create shorter visual axis for measurement accuracy plots
graph combine xaxis visualaxis, col(1) graphregion(col(white)) xcommon imargin(zero) graphregion(margin(l=0 r=0 t=0 b=0)) name(combinedxaxis2, replace) nodraw fysize(70) fxsize(160)

* shorter oximeter labels
cap g byte zero = 0
#delimit ;
twoway 
	(line zero ITA, lw(none))
	,
	by(o, note("") col(5) legend(off) plotregion(margin(l+11)))
	subti(,bc(none) col("117 116 119"))
	yti("") ylab(none) ysc(noline)
	xti("")	xlab(none) xsc(noline)
	fysize(10) fxsize(160) legend(off) plotregion(margin(l=0 b=0 r=0))
	name(oximeters2, replace) nodraw
; #delimit cr

* bias, precision and accuracy at different levels of SaO2
foreach y in bias precision arms {
	graph combine oximeters2 `y'_88 `y'_92 `y'_96 combinedxaxis2, col(1) graphregion(col(white)) xcommon imargin(small) graphregion(margin(l=0 r=0)) xsize(20) ysize(15) name(Combined_`y', replace) scale(*1.35)
	graph export ${OutputDir}\CombinedLines_`y'.svg, replace
	graph export ${OutputDir}\CombinedLines_`y'.pdf, replace
	graph export ${OutputDir}\CombinedLines_`y'.png, replace
}

* FNR and FPR 
graph combine oximeters oneminus_cases_sp94orless oneminus_noncases_sp94orless combinedxaxis2, col(1) graphregion(col(white)) xcommon imargin(small) graphregion(margin(l=0 r=0)) xsize(20) ysize(11.5) name(FNR_FPR_sp94, replace) scale(*1.35)
graph export ${OutputDir}\FNR_FPR_sp94.svg, replace
graph export ${OutputDir}\FNR_FPR_sp94.pdf, replace
graph export ${OutputDir}\FNR_FPR_sp94.png, replace


