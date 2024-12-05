use "../data/02-analysis_data/housing_data.dta", clear

// //Save a scatter plot of price on min_dist
scatter price min_dist, ytitle("Price") xtitle("Distance to the Closest Station")
graph export "../figs/price_distance_scatter.png", replace

//Drop NaN or Price/Distance is <= 0
drop if missing(price) | missing(min_dist)
drop if price <= 0 | min_dist <= 0

//Windsorize at the 95th
summarize min_dist, detail
local p95_dist = r(p95)

replace min_dist = `p95_dist' if min_dist > `p95_dist'

// //Save histograms of Price and Distance for completeness
histogram price, title("Histogram of Price")
graph export "../figs/hist_price.png", replace

histogram min_dist, title("Histogram of Distance to the Closest Station")
graph export "../figs/hist_min_dist.png", replace

//Log-Price
gen log_price = log(price)
histogram log_price, title("Histogram of Log-Price")
graph export "../figs/hist_log_price.png", replace

scatter log_price min_dist, ytitle("Log Price") xtitle("Distance to the Closest Station")
graph export "../figs/log_price_distance_scatter.png", replace
estimates drop _all

estpost summarize log_price min_dist

esttab using "../tables/simple_univariate_summary_stats_table.tex", ///
    title("Summary Statistics") ///
    cells(mean sd count) ///
    label ///
    booktabs ///
    alignment(c) ///
    replace
estimates drop _all
//Regression results
reg log_price min_dist, robust
// reg log_price min_dist, robust coeflegend
eststo

esttab using "../tables/simple_regression_table.tex", ///
    title("Regression Results") ///
    label ///
    se ///
    star(* 0.05 ** 0.01 *** 0.001) ///
    booktabs ///
    alignment(c) ///
    longtable ///
    stats(r2 N, labels("R-squared" "Observations")) /// Include R-squared and Number of Observations
    replace
