/*******************************************************************************
Project: EXAKT
Do file for: Supplementary table 1 (by skin tone group)
*******************************************************************************/

* config
version 17
set varabbrev off
set more off

*** Table 1 
use EXAKT$ExtractDate if RepeatNumber == 1, clear // Only keeping 1 obs per patient

keep Label calage sex ethng skincat chronic_resp raicu1_2 // Simple variables for describing

** Sorting out variables so easy to count them all
g calage_notmiss = 1 if !mi(calage)

g male =  (sex == "M")
g male_notmiss = 1 if !mi(sex) /* WNC 24feb: denominator updated from !mi(male) */

g eth = 1 if !mi(ethng) & ethng != 9
g eth_white = 1 if ethng == 1
g eth_asian = 1 if ethng == 3
g eth_black = 1 if ethng == 4
g eth_mixedother = 1 if ethng == 5 | ethng == 2

* BMJ resubmission
g skincatm = skincat
recode skincatm 6 = 5
g skin = 6 - skincatm /*to align with new column order */
label define skin 1 "Light/very light" 2 "Intermediate" 3 "Tan" 4 "Brown" 5 "Dark"
label values skin skin

* Chronic respiratory disease 
g crd_notmiss = !mi(chronic_resp)
g crd = 1 if chronic_resp == "Yes"

* Reason for admission
g raicu = 1 if !mi(raicu1_2)
g raicu_resp = 1 if raicu1_2 == 1
g raicu_cardio = 1 if raicu1_2 == 2
g raicu_other = 1 if raicu1_2 != 1 & raicu1_2 != 2 & !mi(raicu1_2)

** Keeping only necessary variables
keep Label calage calage_notmiss male male_notmiss eth eth_* skin crd_notmiss crd raicu raicu_*

* Counts ofeach
g ind = 1
collapse (mean) calage (sd) calage_sd = calage (sum) ind calage_notmiss male male_notmiss eth eth_* crd_notmiss crd raicu raicu_*, by(skin)

* Going through and creating columns for each row of the output table

* Total
g val1 = string(ind)

* Age
g val2 = string(calage, "%4.1f") + " (" + string(calage_sd, "%4.1f") + ") [" + string(calage_notmiss, "%3.0f") + "]" 

* Sex
g val3 = string(male, "%3.0f") + " (" + string(100*male/male_notmiss, "%4.1f") + "%) [" + string(male_notmiss, "%3.0f") + "]" 

* Ethnicity
g val4 = "[N = " + string(eth, "%3.0f") + " (" + string(100*eth/ind, "%4.1f") + "%)]"
local i 4
foreach var in  "white" "asian" "black" "mixedother" {
	local i = `i'+1
	g val`i' = string(eth_`var', "%3.0f") + " (" + string(100*eth_`var'/eth, "%4.1f") + "%)"		
}

* crd
g val10 = string(crd, "%3.0f") + " (" + string(100*crd/crd_notmiss, "%4.1f") + "%) [" + string(crd_notmiss, "%3.0f") + "]"

* Admission reason
g val11 = "[N = " + string(raicu, "%3.0f") + " (" + string(100*raicu/ind, "%4.1f") + "%)]"
local i 11
foreach var in  "resp" "cardio" {
	local i = `i'+1
	g val`i' = string(raicu_`var', "%3.0f") + " (" + string(100*raicu_`var'/raicu, "%4.1f") + "%)"		
}

keep skin val*
reshape long val, i(skin)
ren _j row
reshape wide val, i(row) j(skin)
ren val1 Lightorverylight
ren val2 Intermediate 
ren val3 Tan
ren val4 Brown
ren val5 Dark
drop row
export excel using "Descriptive results by skin tone.xlsx", sheet("Table 1", modify) cell(B2)

* import & transform data for Table 2
use EXAKT$ExtractDate, clear
replace OXIMETER_1 = OXIMETER_1[_n-1] if mi(OXIMETER_1) 
replace OXIMETER_2 = OXIMETER_2[_n-1] if mi(OXIMETER_2) 
g OXIMETER_3 = "Total" // Total column in addition to others
** Just for use in seeing if SPO2 is available - not used otherwise
g SPO2_OXI3 = SPO2_OXI1
replace SPO2_OXI3 = SPO2_OXI2 if mi(SPO2_OXI3)
reshape long OXIMETER_ SPO2_OXI, i(Label RepeatNumber) j(oximeter_n)

* Making time usable
g double dtpdc =  dhms(date(substr(DTPDC,1,10),"DMY"), ///
	real(substr(DTPDC,12,2)),real(substr(DTPDC,15,2)),real(substr(DTPDC,18,2)))
format dtpdc %tc

*If a valid pair
replace HB = . if inlist(HB, -1,-2,-3)
replace CO_HB = . if inlist(CO_HB, -1,-2,-3)
replace MET_HB = . if inlist(MET_HB, -1,-2,-3)
g pair = !mi(SAO2_PDC, SPO2_OXI,HB, ITA)
drop if pair == 0
* Drop missing values

*BMJ resubmission
drop _merge
reshape wide OXIMETER_ SPO2_OXI, i(Label RepeatNumber) j(oximeter_n)

g skincatm = skincat
recode skincatm 6 = 5
g skin = 6 - skincatm /*to align with new column order */
label define skin 1 "Light/very light" 2 "Intermediate" 3 "Tan" 4 "Brown" 5 "Dark"
label values skin skin

* Get tabulation by SAO2 subgroup
replace SAO2_PDC = round(SAO2_PDC)
g sao2_88 = (SAO2_PDC < 88) /* WNC 26feb: updated from (SAO2_PDC <= 88) to reflect current Table 1 */
g sao2_8892 = (SAO2_PDC >= 88 & SAO2_PDC <= 92) /* WNC 26feb: updated from (SAO2_PDC > 88 & SAO2_PDC <= 92) to reflect current Table 1 */
g sao2_9294 = (SAO2_PDC > 92 & SAO2_PDC <= 94)
g sao2_94 = (SAO2_PDC > 94)


* Collapse overall
collapse (sum) pairs = pair sao2_88 sao2_8892 sao2_9294 sao2_94 (median) med_sao2 = SAO2_PDC med_hb = HB med_cohb = CO_HB med_methb = MET_HB (p25)  lq_sao2 = SAO2_PDC lq_hb = HB lq_cohb = CO_HB lq_methb = MET_HB (p75) uq_sao2 = SAO2_PDC uq_hb = HB uq_cohb = CO_HB uq_methb = MET_HB, by(skin)

* Values for the data looping through rows
g val1 = string(pairs)
g val2 = trim(string(med_sao2, "%4.0f")) + " (" + trim(string(lq_sao2, "%4.0f")) + ", " + trim(string(uq_sao2, "%4.0f")) + ")"		

g val3 = ""
local i 3

foreach var in  "sao2_88" "sao2_8892" "sao2_9294" "sao2_94" {
	local i = `i'+1
	g val`i' = string(`var', "%4.0f") + " (" + string(100*`var'/pairs, "%4.1f") + "%)"		
}

g val8 = string(med_hb, "%4.0f") + " (" + string(lq_hb, "%4.0f") + ", " + string(uq_hb, "%4.0f") + ")"		
g val9 = string(med_cohb, "%4.1f") + " (" + string(lq_cohb, "%4.1f") + ", " + string(uq_cohb, "%4.1f") + ")"		
g val10 = string(med_methb ,"%4.1f") + " (" + string(lq_methb, "%4.1f") + ", " + string(uq_methb, "%4.1f") + ")"		

keep skin val*
reshape long val, i(skin)
ren _j row
reshape wide val, i(row) j(skin)
ren val1 Lightorverylight
ren val2 Intermediate 
ren val3 Tan
ren val4 Brown
ren val5 Dark
drop row
export excel using "Descriptive results by skin tone.xlsx", sheet("Table 2", modify) cell(B2)