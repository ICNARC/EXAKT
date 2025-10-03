# EXAKT
Analysis code used in the study "Exploring pulse oXimeter Accuracy across sKin Tones (EXAKT): A study within a trial to determine the effect of skin  tone on the diagnostic accuracy of pulse oximeters" (award ID NIHR135577) https://www.icnarc.org/research-studies/exakt/

These Stata 18 (https://www.stata.com/) do files are intended to work with data that are unpublished but can be made available upon request (subject to information governance approvals, controls and cost recovery) via ICNARC's Data Access and Analysis Requests service: https://www.icnarc.org/data-services/access-our-data/

The first do file <do 0 EXAKT Master do file.do> sets up global configuration, defines a small program for outputting results, -excel-, and summarises the remaining do files. With data files loaded and the directory set accordingly at the top of this do file, it will call the remaining do files and complete the analysis.
