/*******************************************************************************
Project: EXAKT
Do file for: Supplementary figure 8 - ITA histogram
*******************************************************************************/

* import & reshape data
use EXAKT$ExtractDate if RepeatNumber == 1, clear

set scheme qqr 
twoway  (histogram ITA,  frequency lcolor(black) fcolor("134 156 196") start(-90) width(5)) ///
		(scatteri 65 -60 "Dark", msymbol(i) mlabpos(0) legend(off) mlabangle(40) mlabcol("117 116 119")) /// 
		(scatteri 65 -10 "Brown", msymbol(i) mlabpos(0) legend(off) mlabangle(40) mlabcol("117 116 119")) /// 
		(scatteri 65 19 "Tan", msymbol(i) mlabpos(0) legend(off) mlabangle(40) mlabcol("117 116 119")) /// 
		(scatteri 66 34.5 "Intermediate", msymbol(i) mlabpos(0) legend(off) mlabangle(40) mlabcol("117 116 119")) /// 
		(scatteri 65 48 "Light", msymbol(i) mlabpos(0) legend(off) mlabangle(40) mlabcol("117 116 119")) /// 
		(scatteri 65 60 "Very light", msymbol(i) mlabpos(0) legend(off) mlabangle(40) mlabcol("117 116 119")) /// 
		(scatteri 0 -30 70 -30, c(l) m(i) lwidth(medthick) lpattern(dash) lcolor("23 74 124")) ///
		(scatteri 0  10 70  10, c(l) m(i) lwidth(medthick) lpattern(dash) lcolor("23 74 124")) ///
		(scatteri 0  28 70  28, c(l) m(i) lwidth(medthick) lpattern(dash) lcolor("23 74 124")) ///
		(scatteri 0  41 70  41, c(l) m(i) lwidth(medthick) lpattern(dash) lcolor("23 74 124")) ///
		(scatteri 0  55 70  55, c(l) m(i) lwidth(medthick) lpattern(dash) lcolor("23 74 124")) ///
		,xla(-90(15)60) yscale( r(0 70)) xsize(8) ysize(4) xti("Individual Typology Angle (ITA), °") yti("Number of patients") yla(0 20 40 60) xsc(reverse)
graph export ${OutputDir}\HistogramITA1.svg, replace
graph export ${OutputDir}\HistogramITA1.pdf, replace
graph export ${OutputDir}\HistogramITA1.png, replace