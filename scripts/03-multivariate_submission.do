log using "../logs/03-multivariate_submission.log", replace
use "../data/02-analysis_data/housing_data.dta", clear
keep price min_dist oldnew year district

//Drop NaN or Price/Distance is <= 0
drop if missing(price) | missing(min_dist)
drop if price <= 0 | min_dist <= 0

//Windsorize at the 95th
summarize min_dist, detail
local p95_dist = r(p95)

replace min_dist = `p95_dist' if min_dist > `p95_dist'

//Log-Price
gen log_price = log(price)
generate min_dist_squared = min_dist^2

encode oldnew, gen(oldnew_encoded)
encode district, gen(district_encoded)
estimates drop _all

estpost summarize min_dist min_dist_squared log_price

// Export summary statistics with mean and SD
esttab using "../tables/numeric_MV_summary_stats.tex", ///
    title("Numeric Variables Summary Statistics") ///
    label ///
    booktabs ///
	longtable ///
    replace ///
    cells("mean sd Var min max")
	
estimates drop _all
estpost tabulate oldnew_encoded
esttab using "../tables/non_numeric_summary_stats_ON.tex", ///
    title("Old/New Summary Statistics") ///
    label ///
    booktabs ///
	longtable ///
    replace ///
	cells("b pct")

estimates drop _all
estpost tabulate district_encoded
esttab using "../tables/non_numeric_summary_stats_district.tex", ///
    title("District Summary Statistics") ///
    label ///
    booktabs ///
	longtable ///
    replace ///
	cells("b pct")
	
estimates drop _all
estpost tabulate year
esttab using "../tables/non_numeric_summary_stats_year.tex", ///
    title("Year Summary Statistics") ///
    label ///
    booktabs ///
	longtable ///
    replace ///
	cells("b pct")

estimates drop _all
//Regression results
reg log_price min_dist min_dist_squared i.oldnew_encoded i.year i.district_encoded c.year#i.district_encoded, robust
// reg log_price min_dist min_dist_squared i.oldnew_encoded i.year c.year#i.district_encoded, robust coeflegend

// Export regression results to LaTeX
esttab using "../tables/multivariate_regression_table.tex", ///
    title("Multivariate regression results, min_dist is a polynomial and in-context with district, year, house age, and district-year interaction fixed effects.") ///
    label ///
    se ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    booktabs ///
    alignment(c) ///
    longtable ///
    stats(r2 N, labels("R-squared" "Observations")) /// Include R-squared and Number of Observations
    replace
	
* Generate fitted values and residuals
predict fitted_values
predict residuals, residuals
egen fitted_bucket = cut(fitted_values), at(10(0.1)14)
collapse (mean) log_price fitted_values residuals, by(fitted_bucket)

* Generate the expected vs actual plot, using bucketed data to make the results more interpretable
* Expected vs Actual
twoway (scatter log_price fitted_bucket, msymbol(circle)) ///
       (line fitted_values fitted_bucket, lcolor(blue)), ///
       title("Bucketed: Expected vs Actual") ///
       xtitle("Predicted", angle(45)) ///
       ytitle("Actual", angle(45))

* Save as png
graph export "../figs/MV_bucketed_expected_vs_actual.png", as(png) replace

* Generate the fitted vs residuals plot, using bucketed data to make the results more interpretable
twoway (scatter residuals fitted_bucket, msymbol(circle)), ///
       title("Bucketed: Fitted vs Residuals") ///
       xlabel(, angle(45)) ylabel(, angle(45))

* Save the plot as a png
graph export "../figs/MV_fitted_vs_residuals.png", as(png) replace
log close
