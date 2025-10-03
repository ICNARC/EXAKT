/*******************************************************************************
Project: EXAKT
Master do file (global config and do file dashboard)
Statisticians: Doidge J, Cowden A, Charles W, Harrison D
*******************************************************************************/

* global config
cd "S:\Stats\7. Confidential\Trials\UK-ROX\EXAKT" //define working directory. All do files should be stored in a subdirectory named "Analysis" or filepaths updated as required, below.
global OutputDir "Analysis\Outputs\BMJ" //define output directory
global LogDir "Analysis\Logs" //define log directory
global ExtractDate "20250217" //used within data file names
set seed 24092222 //set random number seed for reproducibility
global bsreps 2000 // set number of bootstrap replications for estimation fo confidence intervals

* define temporary program for outputting results to excel
cap prog drop excel
prog excel
	putexcel A2 = ("Light")
	putexcel A3 = ("Intermediate")
	putexcel A4 = ("Tan")
	putexcel A5 = ("Brown")
	putexcel A6 = ("Dark")
	putexcel A7 = ("Overall")
	putexcel A8 = ("Range over skin tones")
	putexcel B1 = ("A")
	putexcel C1 = ("B")
	putexcel D1 = ("C")
	putexcel E1 = ("D")
	putexcel F1 = ("E")
	putexcel G1 = ("Overall")
end

*** Do files need to be run in this order (or at least do 1 and then 3 prior to analyses)

* derive ITA, skin tone categories and SaO2 categories
// NB: requires raw CRF extract linked to CMP data <EXAKT20250217_postlinkage.dta> or equivalently structured file
do "Analysis\do 1 Raw data.do"

* Table 1 of patient characteristics and ABG observations
do "Analysis\do 2.1 descriptive tables.do" 

* Figure 2 - Banana plots
do "Analysis\do 2.2 descriptive graphs.do" 

* Supplementary table 1 (by skin tone category)
do "Analysis\do 2.3 descriptive tables skintone"

* Fit regression models
do "Analysis\do 3 regression models.do"

* Supplementary tables 2 - 7
do "Analysis\do 4.1 Raw measurement accuracy.do" //Unadjusted bias, precision and Arms
do "Analysis\do 4.2.1.1 Predicting bias.do" //Adjusted bias estimates - overall
do "Analysis\do 4.2.1.2 Predicting bias at sao2 values.do" //Adjusted bias estimates at fixed values of SaO2 [replaced with SaO2<92 in response to reviewers' comments - see do 4.5.1]
do "Analysis\do 4.2.2.1 Predicting rmse.do" //Adjusted precision estimates - overall
do "Analysis\do 4.2.2.2 Predicting rmse at sao2 values.do" //Adjusted precision estimates at fixed values of SaO2 [replaced with SaO2<92 in response to reviewers' comments - see do 4.5.2]
do "Analysis\do 4.2.3.1 Predicting arms.do" //Adjusted Arms estimates - overall
do "Analysis\do 4.2.3.2 Predicting arms at sao2 values.do" //Adjusted Arms estimates at fixed values of SaO2 [replaced with SaO2<92 in response to reviewers' comments - see do 4.5.3]

do "Analysis\do 4.3 Raw diagnostic accuracy.do" //Unadjusted diagnostic accuracy (Sn, Sp, FPR, FNR, AUROC)
do "Analysis\do 4.4.1.1 Predicting diagnostic accuracy.do" //Adjusted diagnostic accuracy (Sn, Sp, FPR, FNR - not AUROC)
do "Analysis\do 4.4.1.2 Predicting diagnostic ranges 92.do" //Adjusted Sn and Sp at threshold of SpO2=92
do "Analysis\do 4.4.1.3 Predicting diagnostic ranges 94.do" //Adjusted Sn and Sp at threshold of SpO2=94
do "Analysis\do 4.4.2.1 Predicting AUROC.do" //Adjusted AUROC (no differences across skin tone)
do "Analysis\do 4.4.2.2 Predicting diagnostic ranges AUROC.do" //Differences across skin tone categories in adjusted AUROC

do "Analysis\do 4.5.0 Raw measurement at sao2 lt 92" //Unadjusted bias, precision and Arms over range of SaO2<92
do "Analysis\do 4.5.1 Predicting bias at sao2 lt 92" //Adjusted bias over range of SaO2<92
do "Analysis\do 4.5.2 Predicting rmse at sao2 lt 92" //Adjusted precision over range of SaO2<92
do "Analysis\do 4.5.3 Predicting arms at sao2 lt 92" //Adjusted Arms over range of SaO2<92

* Regression model graphs
do "Analysis\do 5.1.1 Prepare data for line graphs.do" //Prepare data for plotting Figures 3 and 4 and supplementary figures 4-6
do "Analysis\do 5.1.2 Line graphs.do" // Supplementary figures 4-6 and a combined version of Figures 3 and 4 replaced by separate versions during peer-review
do "Analysis\do 5.2 heatmaps.do" // Supplementary Figure 7
do "Analysis\do 5.3 scatterplots 5x2 (by pulse oximeter)"// Figure 2 and Supplementary Figures 3A-3E
do "Analysis\do 5.4 Line Graphs Separated"// Figures 3 and 4

* Supplementary figure 8 - histogram of ITA
do "Analysis\do 6 histogram of ITA"
