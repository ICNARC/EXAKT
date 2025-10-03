/*******************************************************************************
Project: EXAKT
Do file for: Figure 2 - Banana plots
*******************************************************************************/

*config
version 17
set varabbrev off
set more off
cd "S:\Stats\7. Confidential\Trials\UK-ROX\EXAKT"

*import data
global DashedDate = substr("$ExtractDate",1,4)+"-"+substr("$ExtractDate",5,2)+"-"+substr("$ExtractDate",7,2)
use EXAKT$ExtractDate, clear
bysort Label RepeatNumber: keep if _n==1


*** Producing banana plots of ITA values including lines separating each categorised group
use EXAKT$ExtractDate, clear
egen Amed = rowmedian(AValue_1 AValue_2 AValue_3 AValue_4)
lab2rgb Lmed Amed Bmed, string

** Creating a value showing the colour associated with each ITA
forvalues i=1/`=_N' {
	if !mi(Lmed[`i']) {
		local scat `"`scat' (scatteri `=Lmed[`i']' `=Bmed[`i']', mc("`=RGB[`i']'") m(o) msize(small))"'
	}
}
	#delimit ;
	twoway `scat'
		(function y=tan(c(pi)*55/180)*x + 50, range(0 `=30*cos(c(pi)*55/180)') lp(shortdash) lw(vthin) lc(gs6))
		(function y=tan(c(pi)*41/180)*x + 50, range(0 `=30*cos(c(pi)*41/180)') lp(shortdash) lw(vthin) lc(gs6))
		(function y=tan(c(pi)*28/180)*x + 50, range(0 `=30*cos(c(pi)*28/180)') lp(shortdash) lw(vthin) lc(gs6))
		(function y=tan(c(pi)*10/180)*x + 50, range(0 `=30*cos(c(pi)*10/180)') lp(shortdash) lw(vthin) lc(gs6))
		(function y=tan(-c(pi)*30/180)*x + 50, range(0 `=30*cos(c(pi)*30/180)') lp(shortdash) lw(vthin) lc(gs6))
		(scatteri `=50+30*sin(c(pi)*62/180)' `=30*cos(c(pi)*62/180)' "Very light" 
		`=50+30*sin(c(pi)*48/180)' `=30*cos(c(pi)*48/180)' "Light" 
		`=50+30*sin(c(pi)*34.5/180)' `=30*cos(c(pi)*34.5/180)' "Tan" 
		`=50+30*sin(c(pi)*19/180)' `=30*cos(c(pi)*19/180)' "Intermediate" 
		`=50-30*sin(c(pi)*10/180)' `=30*cos(c(pi)*10/180)' "Brown" 
		`=50-30*sin(c(pi)*50/180)' `=30*cos(c(pi)*50/180)' "Dark", m(i) mlabp(0) mlabc("117 116 119") mlabs(medsmall))
		,
		scheme(qqr) 
		yti("Lightness (L*)")
		xti("Yellow colour (b*)", margin(t+2))
		ylab(0(20)80, nogrid) xlab(0(10)30)
		legend(off) xsize(4) graphregion(col(none) margin(r+13)) plotregion(margin(0 0 0 0))
	; #delimit cr

gr export "${OutputDir}\\banana_by_skintone.svg", replace


use EXAKT$ExtractDate if RepeatNumber == 1, clear
egen Amed = rowmedian(AValue_1 AValue_2 AValue_3 AValue_4)
lab2rgb Lmed Amed Bmed, string

* import & transform data as each patient has 2 oximeters
reshape long OXIMETER_ SPO2_OXI, i(Label RepeatNumber) j(oximeter_n)
bysort Label oximeter_n (OXIMETER_): replace OXIMETER_ = OXIMETER_[_N]
encode OXIMETER_ if !inlist(OXIMETER_,"-1","-2","-3"), gen(o)
lab var o "Pulse oximeter model"
forvalues j=1/5 {
	local c`j' 1
	gen col`j'=.
	local cols`j'
}
drop if mi(o)
forvalues i=1/`=_N' {
	if !mi(Lmed[`i']) {
		local j=o[`i']
		replace col`j'=`c`j'++' in `i'
		local cols`j' `"`cols`j'' "`=RGB[`i']'""'
	}
}
local title1 "A"
local title2 "B"
local title3 "C"
local title4 "D"
local title5 "E"
forvalues j = 1/5 {
	#delimit ;
	twoway (scatter Lmed Bmed if o==`j', m(o) msize(small) colorvar(col`j') colordiscrete colorlist(`cols`j''))
		(function y=tan(c(pi)*55/180)*x + 50, range(0 `=32*cos(c(pi)*55/180)') lp(shortdash) lw(vthin) lc(gs6))
		(function y=tan(c(pi)*41/180)*x + 50, range(0 `=32*cos(c(pi)*41/180)') lp(shortdash) lw(vthin) lc(gs6))
		(function y=tan(c(pi)*28/180)*x + 50, range(0 `=32*cos(c(pi)*28/180)') lp(shortdash) lw(vthin) lc(gs6))
		(function y=tan(c(pi)*10/180)*x + 50, range(0 `=32*cos(c(pi)*10/180)') lp(shortdash) lw(vthin) lc(gs6))
		(function y=tan(-c(pi)*30/180)*x + 50, range(0 `=32*cos(c(pi)*30/180)') lp(shortdash) lw(vthin) lc(gs6))
		(scatteri `=50+32*sin(c(pi)*62/180)' `=32*cos(c(pi)*62/180)' "Very light" 
		`=50+32*sin(c(pi)*48/180)' `=32*cos(c(pi)*48/180)' "Light" 
		`=50+32*sin(c(pi)*34.5/180)' `=32*cos(c(pi)*34.5/180)' "Tan" 
		`=50+32*sin(c(pi)*19/180)' `=32*cos(c(pi)*19/180)' "Intermediate" 
		`=50-32*sin(c(pi)*10/180)' `=32*cos(c(pi)*10/180)' "Brown" 
		`=50-32*sin(c(pi)*50/180)' `=32*cos(c(pi)*50/180)' "Dark", m(i) mlabp(0) mlabc("117 116 119") mlabs(small))
		, subti("`title`j''", bc(none) col("117 116 119"))
		scheme(qqr) 
		yti("Lightness (L*)")
		xti("Yellow colour (b*)", margin(t+2))
		ylab(0(20)80, nogrid) xlab(0(10)30)
		legend(off) clegend(off)
		xsize(4) ysize(6) graphregion(col(none) margin(r+13)) plotregion(margin(0 0 0 0)) aspect(`=8/3')
		name(p`j', replace)
	; #delimit cr
 	gr export "${OutputDir}\\banana_by_skintone_`j'.svg", replace name(p`j')
}
graph combine p1 p2 p3 p4 p5, row(1) xsize(15) ysize(8) imargin(medium) iscale(*.8) graphr(margin(r+5))
gr export "${OutputDir}\\banana_by_skintone_and_oximeter.svg", replace
gr export "${OutputDir}\\banana_by_skintone_and_oximeter.pdf", replace