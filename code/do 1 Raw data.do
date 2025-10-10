/*******************************************************************************
Project: EXAKT
Do file for: deriving ITA, skin tone categories and SaO2 categories
*******************************************************************************/

* Obtain dataset of data linked with CMP and sources merged together
use EXAKT${ExtractDate}_postlinkage, clear

* derive ITA values using patient median values
forval i=1/4{
	replace LValue_`i' = . if LValue_`i' < 0
	replace BValue_`i' = . if BValue_`i' < 0
	replace AValue_`i' = . if AValue_`i' < 0
}
foreach v in L B{
	egen `v'med = rowmedian(`v'Value_1 `v'Value_2 `v'Value_3 `v'Value_4)
}
g ITA = atan((Lmed - 50)/Bmed)*180/_pi
bysort Label (RepeatNumber): replace ITA = ITA[1]
desc ITA

* derive skin categores proposed by Chardon, A., I. Cretois and C. Hourseau (1991) Skin colour typology and suntanning pathways. Int. J. Cosmet. Sci 13, 191–208.
g skincat = cond(ITA==.,.,cond(ITA>55,6,cond(ITA>41,5,cond(ITA>28,4,cond(ITA>10,3,cond(ITA>-30,2,1))))))
lab def skincat 1 "Dark" 2 "Brown" 3 "Tan" 4 "Intermediate" 5 "Light" 6 "Very light"
lab val skincat skincat

g skincat7 = cond(ITA==.,.,cond(ITA>55,6,cond(ITA>41,5,cond(ITA>28,4,cond(ITA>10,3,cond(ITA>-30,2,cond(ITA>-50,1,0)))))))
lab def skincat7 0 "Very dark" 1 "Dark" 2 "Brown" 3 "Tan" 4 "Intermediate" 5 "Light" 6 "Very light"
lab val skincat7 skincat7

sort Label RepeatNumber

* Categorise core data
foreach v in SPO2_OXI1 SPO2_OXI2 SAO2_PDC{
	replace `v' = . if `v' < 0
}
egen SAO2cat = cut(SAO2_PDC), at(0,88,92,96,101) icodes
lab def SAO2cat 0 "< 88" 1 "88-91" 2 "92-95" 3 "96-100"
lab val SAO2cat SAO2cat 
tab SAO2cat if !mi(ITA) & (!mi(SPO2_OXI1) | !mi(SPO2_OXI2))

* count records with core data available
g core = !mi(ITA) & !mi(SAO2_PDC) & (!mi(SPO2_OXI1) | !mi(SPO2_OXI2))
lab var core "Core data available (ITA, SpO2, SaO2)"
tab core if RepeatNumber==1
tab core 
tab skincat7 if RepeatNumber == 1
tab ethng if RepeatNumber == 1

* count records with core data available at any point
bys Label : egen maxcore = max(core)

** Saving extract for analysis
save EXAKT$ExtractDate, replace
