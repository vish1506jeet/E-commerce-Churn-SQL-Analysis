E-commerce Churn SQL Analysis

End-to-end data cleaning, validation, and churn analysis performed entirely in PostgreSQL on a 5,630 row e-commerce customer dataset, from raw import to analysis ready tables, with no external tools used for cleaning.

#Objective

Retail and e-commerce businesses lose revenue when they can't identify which customers are at risk of leaving and why. This project takes a raw, unclean customer dataset and turns it into a reliable base for churn analysis, then surfaces the factors most associated with customer churn, entirely through SQL, demonstrating that meaningful analysis doesn't require leaving the database layer.

#Dataset

5,630 customers, 20 original features spanning login device, payment behavior, order category, tenure, satisfaction score, complaint history, and order activity.

#What I Did

1. Built a repeatable import pipeline
Converted the source spreadsheet to CSV and loaded it into a staging table (ecommerce_raw) matched column-for-column to the source schema, keeping the raw import untouched as a permanent reference point separate from any cleaning work.

2. Diagnosed and standardized inconsistent categorical data
Used `GROUP BY` frequency checks across every categorical column and found the same real-world category recorded under multiple labels — `"Phone"` vs `"Mobile Phone"`, `"CC"` vs `"Credit Card"`, `"COD"` vs `"Cash on Delivery"`. Left unmerged, this kind of inconsistency silently fragments a "true" category into several, distorting any group-by analysis without ever throwing an error. Consolidated all instances using `CASE` expressions.

3. Quantified and resolved missing data without discarding rows
Counted NULLs across 7 numeric columns (each ~4–5% missing) and imputed using each column's **median**, computed with `PERCENTILE_CONT` — chosen specifically over mean imputation because it's resistant to skew from outliers, and over row deletion because dropping ~5% of rows per column would have compounded into a much larger loss of usable data across the full table.

4. Found and fixed a real data-entry error using distribution analysis
This is the part I'm most proud of: rather than just checking column types, I profiled the actual *distribution* of every numeric column. `WarehouseToHome` (delivery distance in km) looked clean at a glance — until I checked its max value against its full distribution and found two isolated values (126, 127) sitting in a total gap above the next-highest real value (36), with zero data points in between.

- *Root cause hypothesis:* a dropped decimal point during entry (e.g. `12.6` entered as `126`)
- *Verification:* dividing both outliers by 10 placed them squarely back inside the dataset's natural 5–36 km range, consistent with every other observed value
- *Fix:* a targeted `UPDATE ... WHERE warehousetohome > 100` correction, re-verified against the full min/max afterward

This is the kind of silent data-quality issue that doesn't throw an error and easily slips into downstream analysis undetected — catching it required actively profiling the data rather than trusting it at face value.

5. Validated the entire cleaned table before treating it as analysis-ready
Checked min/max ranges across all 22 columns against what's realistic for each field (e.g. satisfaction score confirmed within 1–5, hours on app within 0–5, city tier within 1–3) to confirm no further hidden errors before moving to analysis.

6. Built readable derived columns and ran the churn analysis
Added `churn_status` and `complaint_status` label columns for query readability, then measured churn rate overall and broken down by login device, payment mode, order category, tenure bucket, complaint status, and satisfaction score — to identify which customer segments and behaviors correlate most strongly with churn.

#Approach

1. Staged the raw import Loaded the source CSV into ecommerce_raw, kept untouched, and did all cleaning on a separate ecommerce_clean table.

2. Standardized categorical data Frequency checks (GROUP BY) turned up the same category recorded under different labels - Phone / Mobile Phone, CC / Credit Card, COD / Cash on Delivery. Merged these with CASE statements so group-by analysis wouldn't silently split one category into two.

3. Handled missing values 7 numeric columns had ~4-5% NULLs. Filled them with each column's median using PERCENTILE_CONT, which holds up better than mean imputation when outliers are present.

4. Found a data entry bug WarehouseToHome looked fine until I checked its distribution: two values (126, 127) sat in an empty gap above the real max of 36. Dividing them by 10 put both back in range, consistent with a dropped decimal point during entry. Confirmed with a targeted UPDATE and re-checked the min/max afterward.

5. Validated the full table Checked min/max ranges across every numeric column against realistic bounds (satisfaction score within 1-5, hours on app within 0-5, etc.) before treating the data as analysis-ready.

6. Ran the churn breakdown Added churn_status and complaint_status label columns, then measured churn rate overall and by device, payment mode, order category, tenure, complaint status, and satisfaction score.

#Outcome

- A fully cleaned, validated, analysis-ready table (`ecommerce_clean`) with zero missing values, zero duplicate category labels, and one confirmed-and-corrected data entry error, built entirely with auditable SQL rather than manual spreadsheet edits
- A reusable, commented SQL script that documents every decision — so the cleaning logic is transparent and repeatable, not a black box

#Findings

Overall churn rate: 16.84% (949 of 5,630 customers).

- Tenure is the dominant driver. Customers in their first 0-2 months churn at 46.5%, nearly 10x the rate of customers with 12+ months tenure (4.9%). No other factor comes close - this points to onboarding and early-experience as the main churn risk, not any single product feature.
- Complaints roughly triple churn risk. Customers who filed a complaint churn at 31.7% vs 10.9% for those who didn't.
- Cash on Delivery and E wallet users churn more than card users. COD sits at 24.9% vs 14.2% for Credit Card, possibly linked to lower payment friction correlating with lower commitment, worth testing further.
- Mobile Phone as an order category churns far more than other categories (27.4% vs 4.9% for Grocery), while Computer as a login device churns more than Mobile Phone as a login device (19.8% vs 15.6%), two different things worth not conflating.
- Counterintuitive result - churn rate increases with satisfaction score (11.5% at score 1, up to 23.8% at score 5). This doesn't fit the usual assumption that satisfied customers stay, and would need further investigation before drawing conclusions, flagged here rather than a forced explanation.

#Recommendation

The biggest lever is early retention. A targeted onboarding or check-in process in the first 60-90 days would address the segment responsible for the largest share of churn, rather than spreading effort evenly across all customers.

#Skills Demonstrated

`SQL` · `PostgreSQL` · `Data Cleaning` · `Data Validation` · `CTEs` · `Window Functions` · `CASE Logic` · `Missing Data Imputation` · `Outlier Detection` · `Exploratory Data Analysis`

#Tools

- PostgreSQL 18
- pgAdmin 4

#Files

- `ecommerce_churn_analysis.sql` — full script covering table creation, cleaning, validation, and analysis queries, with inline comments explaining each step
