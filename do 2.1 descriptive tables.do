/*******************************************************************************
Project: EXAKT
Do file for: Table 1 (output as Table 1 and Table 2 then combined in manuscript)
*******************************************************************************/

* config
version 17
set varabbrev off
set more off

*** Table 1 
use EXAKT$ExtractDate if RepeatNumber == 1, clear // Only keeping 1 obs per patient
g OXIMETER_3 = "Total" // Adding an overall column
reshape long OXIMETER_ SPO2_OXI, i(Label RepeatNumber) j(oximeter_n) // Reshaping for where patients have multiple oximeters 
drop if OXIMETER_ == "-2" // 1 patient only 1 ocimeter
encode OXIMETER_, gen(o) // Easier to run
keep Label o calage sex ethng skincat chronic_resp raicu1_2 // Simple variables for describing

** Sorting out variables so easy to count them all
g calage_notmiss = 1 if !mi(calage)

g male =  (sex == "M")
g male_notmiss = 1 if !mi(sex) /* WNC 24feb: denominator updated from !mi(male) */

g eth = 1 if !mi(ethng) & ethng != 9
g eth_white = 1 if ethng == 1
g eth_asian = 1 if ethng == 3
g eth_black = 1 if ethng == 4
g eth_mixedother = 1 if ethng == 5 | ethng == 2

g skin = 1 if !mi(skincat)
g skin_light = 1 if skincat == 5 | skincat == 6
g skin_inter = 1 if skincat == 4
g skin_tan = 1 if skincat == 3
g skin_brown = 1 if skincat == 2
g skin_dark = 1 if skincat == 1

* Chronic respiratory disease 
g crd_notmiss = !mi(chronic_resp)
g crd = 1 if chronic_resp == "Yes"

* Reason for admission
g raicu = 1 if !mi(raicu1_2)
g raicu_resp = 1 if raicu1_2 == 1
g raicu_cardio = 1 if raicu1_2 == 2
g raicu_other = 1 if raicu1_2 != 1 & raicu1_2 != 2 & !mi(raicu1_2)

** Keeping only necessary variables
keep Label o calage calage_notmiss male male_notmiss eth eth_* skin skin_* crd_notmiss crd raicu raicu_*

* Counts ofeach
g ind = 1
collapse (mean) calage (sd) calage_sd = calage (sum) ind calage_notmiss male male_notmiss eth eth_* skin skin_* crd_notmiss crd raicu raicu_*, by(o)

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

* Skincategory
g val10 = "[N = " + string(skin, "%3.0f") + " (" + string(100*skin/ind, "%4.1f") + "%)]"
local i 10
foreach var in  "light" "inter" "tan" "brown" "dark" {
	local i = `i'+1
	g val`i' = string(skin_`var', "%3.0f") + " (" + string(100*skin_`var'/skin, "%4.1f") + "%)"		
}

g val17 = string(crd, "%3.0f") + " (" + string(100*crd/crd_notmiss, "%4.1f") + "%) [" + string(crd_notmiss, "%3.0f") + "]"

* Skincategory
g val18 = "[N = " + string(raicu, "%3.0f") + " (" + string(100*raicu/ind, "%4.1f") + "%)]"
local i 18
foreach var in  "resp" "cardio" "other" {
	local i = `i'+1
	g val`i' = string(raicu_`var', "%3.0f") + " (" + string(100*raicu_`var'/raicu, "%4.1f") + "%)"		
}

keep o val*
reshape long val, i(o) // Changing oximeters to be wide rather than long
ren _j row
reshape wide val, i(row) j(o )
ren val1 A 
ren val2 B
ren val3 C 
ren val4 D
ren val5 E
ren val6 Total
drop row
export excel using "${OutputDir}\\Descriptive results.xlsx", sheet("Table 1", modify) cell(B2)

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

* Get tabulation by SAO2 subgroup
replace SAO2_PDC = round(SAO2_PDC)
g sao2_88 = (SAO2_PDC < 88) /* WNC 26feb: updated from (SAO2_PDC <= 88) to reflect current Table 1 */
g sao2_8892 = (SAO2_PDC >= 88 & SAO2_PDC <= 92) /* WNC 26feb: updated from (SAO2_PDC > 88 & SAO2_PDC <= 92) to reflect current Table 1 */
g sao2_9294 = (SAO2_PDC > 92 & SAO2_PDC <= 94)
g sao2_94 = (SAO2_PDC > 94)


* Collapse overall
collapse (sum) pairs = pair sao2_88 sao2_8892 sao2_9294 sao2_94 (median) med_sao2 = SAO2_PDC med_hb = HB med_cohb = CO_HB med_methb = MET_HB (p25)  lq_sao2 = SAO2_PDC lq_hb = HB lq_cohb = CO_HB lq_methb = MET_HB (p75) uq_sao2 = SAO2_PDC uq_hb = HB uq_cohb = CO_HB uq_methb = MET_HB, by(OXIMETER_)

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

keep OXIMETER_ val*
reshape long val, i(OXIMETER_)
ren _j row
reshape wide val, i(row) j(OXIMETER_, string )
ren val* *
drop row
export excel using "${OutputDir}\\Descriptive results.xlsx", sheet("Table 2", modify) cell(B2)