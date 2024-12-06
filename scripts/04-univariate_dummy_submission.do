log using "../logs/04-univariate_dummy_submission.log", replace
use "../data/02-analysis_data/housing_data.dta", clear

// Drop NaN or Price/Distance is <= 0
drop if missing(price) | missing(min_dist)
drop if price <= 0 | min_dist <= 0

// Winsorize at the 95th percentile
summarize min_dist, detail
local p95_dist = r(p95)
replace min_dist = `p95_dist' if min_dist > `p95_dist'

// Convert min_dist to binary: 1 if min_dist < 2000, 0 otherwise
replace min_dist = (min_dist < 2000)

// Log-transform the price
gen log_price = log(price)

// Clear previous estimates
estimates drop _all

// Regression results
reg log_price min_dist, robust
reg log_price min_dist, robust coeflegend
eststo

esttab using "../tables/dummy_simple_regression_table.tex", ///
    title("Regression results for the close/far dummy variable. Shows us the relationship is economically piece wise.") ///
    label ///
    se ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    booktabs ///
    alignment(c) ///
    longtable ///
    stats(r2 N, labels("R-squared" "Observations")) /// Include R-squared and Number of Observations
    replace

log close
