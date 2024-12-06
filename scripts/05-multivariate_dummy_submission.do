log using "../logs/05-multivariate_dummy_submission.log", replace
use "../data/02-analysis_data/housing_data.dta", clear
keep price min_dist oldnew year district

// Drop missing values or observations where Price/Distance is <= 0
drop if missing(price) | missing(min_dist)
drop if price <= 0 | min_dist <= 0

// Winsorize min_dist at the 95th percentile
summarize min_dist, detail
local p95_dist = r(p95)
replace min_dist = `p95_dist' if min_dist > `p95_dist'

// Convert min_dist to a dummy variable: 1 if min_dist < 2000, 0 otherwise
replace min_dist = (min_dist < 2000)

// Generate log_price
gen log_price = log(price)

// Encode categorical variables
encode oldnew, gen(oldnew_encoded)
encode district, gen(district_encoded)
estimates drop _all

// Regression results without min_dist_squared
reg log_price i.min_dist i.oldnew_encoded i.year i.district_encoded c.year#i.district_encoded
// reg log_price i.min_dist i.oldnew_encoded c.year##i.district_encoded, robust coeflegend

// Export regression results to LaTeX
esttab using "../tables/dummy_MV_regression_table.tex", ///
    title("Regression results using the close/far dummy Min_dist is either 0 or 1. Shows us that the dummy effect is still economically and statistically significant in-context with our controls." ) ///
    label ///
    se ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    booktabs ///
    alignment(c) ///
    longtable ///
    stats(r2 N, labels("R-squared" "Observations")) /// Include R-squared and Number of Observations
    replace

// Generate fitted values and residuals
predict fitted_values
predict residuals, residuals

// Create buckets for fitted values
egen fitted_bucket = cut(fitted_values), at(10(0.1)14)
collapse (mean) log_price fitted_values residuals, by(fitted_bucket)

// Generate the expected vs actual plot
twoway (scatter log_price fitted_bucket, msymbol(circle)) ///
       (line fitted_values fitted_bucket, lcolor(blue)), ///
       title("Bucketed: Expected vs Actual") ///
       xtitle("Predicted", angle(45)) ///
       ytitle("Actual", angle(45))

// Save the plot as png
graph export "../figs/bucketed_dummy_expected_vs_actual.png", as(png) replace

// Generate the fitted vs residuals plot
twoway (scatter residuals fitted_bucket, msymbol(circle)), ///
       title("Bucketed: Fitted vs Residuals") ///
       xlabel(, angle(45)) ylabel(, angle(45))

// Save the plot as png
graph export "../figs/dummy_fitted_vs_residuals.png", as(png) replace
log close
