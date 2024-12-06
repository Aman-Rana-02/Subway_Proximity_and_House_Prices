log using "../logs/01-convert_raw_to_dta.log", replace
import delimited "../data/01-raw_data/housing_data.csv", clear
keep price min_dist oldnew year district
save "../data/02-analysis_data/housing_data.dta", replace
log close
