#Creating a table to hold the raw imported data
CREATE TABLE ecommerce_raw ( CustomerID INT, Churn SMALLINT, Tenure NUMERIC, PreferredLoginDevice VARCHAR(50),
							CityTier SMALLINT, WarehouseToHome NUMERIC, PreferredPaymentMode VARCHAR(50), Gender VARCHAR(20),
							HourSpendOnApp NUMERIC, NumberOfDeviceRegistered SMALLINT, PreferedOrderCat VARCHAR(50),
							SatisfactionScore SMALLINT, MaritalStatus VARCHAR(20), NumberOfAddress SMALLINT, Complain SMALLINT,
							OrderAmountHikeFromlastYear NUMERIC, CouponUsed NUMERIC, OrderCount NUMERIC, DaySinceLastOrder NUMERIC,
							CashbackAmount NUMERIC );

#Checking the total number of rows loaded
SELECT COUNT(*) FROM ecommerce_raw;

#Checking distinct values in PreferredLoginDevice for inconsistent labels
SELECT preferredlogindevice, COUNT(*) FROM ecommerce_raw
GROUP BY preferredlogindevice
ORDER BY 1

#Checking distinct values in PreferredPaymentMode for inconsistent labels
SELECT preferredpaymentmode, COUNT(*) FROM ecommerce_raw
GROUP BY preferredpaymentmode
ORDER BY 1

#Checking distinct values in PreferedOrderCat for inconsistent labels
SELECT preferedordercat, COUNT(*) FROM ecommerce_raw
GROUP BY preferedordercat
ORDER BY 1

#Counting NULL values in each numeric column
SELECT
  COUNT(*) FILTER (WHERE tenure IS NULL) AS tenure_nulls,
  COUNT(*) FILTER (WHERE warehousetohome IS NULL) AS warehouse_nulls,
  COUNT(*) FILTER (WHERE hourspendonapp IS NULL) AS hours_nulls,
  COUNT(*) FILTER (WHERE orderamounthikefromlastyear IS NULL) AS hike_nulls,
  COUNT(*) FILTER (WHERE couponused IS NULL) AS coupon_nulls,
  COUNT(*) FILTER (WHERE ordercount IS NULL) AS ordercount_nulls,
  COUNT(*) FILTER (WHERE daysincelastorder IS NULL) AS daysince_nulls
FROM ecommerce_raw;

#Creating a working copy of the raw table for cleaning
CREATE TABLE ecommerce_clean
AS SELECT * FROM ecommerce_raw;

#Merging duplicate category labels into single consistent values
UPDATE ecommerce_clean
SET
  preferredlogindevice = CASE WHEN preferredlogindevice = 'Phone'
  THEN 'Mobile Phone' ELSE preferredlogindevice END,
  preferredpaymentmode = CASE
    WHEN preferredpaymentmode = 'CC' THEN 'Credit Card'
    WHEN preferredpaymentmode = 'COD' THEN 'Cash on Delivery'
    ELSE preferredpaymentmode
  END,
  preferedordercat = CASE WHEN preferedordercat = 'Mobile'
  THEN 'Mobile Phone' ELSE preferedordercat END;

#Filling missing numeric values with each columns median
WITH medians AS (
  SELECT
    percentile_cont(0.5) WITHIN GROUP (ORDER BY tenure) AS tenure_med,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY warehousetohome) AS warehouse_med,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY hourspendonapp) AS hours_med,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY orderamounthikefromlastyear) AS hike_med,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY couponused) AS coupon_med,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY ordercount) AS ordercount_med,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY daysincelastorder) AS daysince_med
  FROM ecommerce_clean
)
UPDATE ecommerce_clean
SET
  tenure = COALESCE(tenure, medians.tenure_med),
  warehousetohome = COALESCE(warehousetohome, medians.warehouse_med),
  hourspendonapp = COALESCE(hourspendonapp, medians.hours_med),
  orderamounthikefromlastyear = COALESCE(orderamounthikefromlastyear, medians.hike_med),
  couponused = COALESCE(couponused, medians.coupon_med),
  ordercount = COALESCE(ordercount, medians.ordercount_med),
  daysincelastorder = COALESCE(daysincelastorder, medians.daysince_med)
FROM medians;

#Verifying no NULLs remain after imputation
SELECT COUNT(*) FILTER (WHERE tenure IS NULL) AS tenure_nulls,
COUNT(*) FILTER (WHERE warehousetohome IS NULL) AS warehouse_nulls,
COUNT(*) FILTER (WHERE hourspendonapp IS NULL) AS hours_nulls,
COUNT(*) FILTER (WHERE orderamounthikefromlastyear IS NULL) AS hike_nulls,
COUNT(*) FILTER (WHERE couponused IS NULL) AS coupon_nulls,
COUNT(*) FILTER (WHERE ordercount IS NULL) AS ordercount_nulls,
COUNT(*) FILTER (WHERE daysincelastorder IS NULL) AS daysince_nulls
FROM ecommerce_clean;

#Re-running the category label merge
UPDATE ecommerce_clean
SET
  preferredlogindevice = CASE WHEN preferredlogindevice = 'Phone'
  THEN 'Mobile Phone' ELSE preferredlogindevice END,
  preferredpaymentmode = CASE
    WHEN preferredpaymentmode = 'CC' THEN 'Credit Card'
    WHEN preferredpaymentmode = 'COD' THEN 'Cash on Delivery'
    ELSE preferredpaymentmode
  END,
  preferedordercat = CASE WHEN preferedordercat = 'Mobile'
  THEN 'Mobile Phone' ELSE preferedordercat END;

#Verifying PreferredLoginDevice labels merged correctly
SELECT preferredlogindevice, COUNT(*) FROM ecommerce_clean
GROUP BY preferredlogindevice
ORDER BY 1;

#Verifying PreferredPaymentMode labels merged correctly
SELECT preferredpaymentmode, COUNT(*) FROM ecommerce_clean
GROUP BY preferredpaymentmode
ORDER BY 1;

#Verifying PreferedOrderCat labels merged correctly
SELECT preferedordercat, COUNT(*) FROM ecommerce_clean
GROUP BY preferedordercat
ORDER BY 1;

#Creating a derived column from Churn for readability
ALTER TABLE ecommerce_clean ADD COLUMN churn_status VARCHAR(20);
UPDATE ecommerce_clean
SET churn_status = CASE WHEN churn = 1
THEN 'Churned' ELSE 'Retained' END;

#Creating a derived column from Complain for readability
ALTER TABLE ecommerce_clean ADD COLUMN complaint_status VARCHAR(20);
UPDATE ecommerce_clean
SET complaint_status = CASE WHEN complain = 1
THEN 'Complained' ELSE 'No Complaint' END;

#Checking every numeric columns min/max range for implausible values
SELECT
  MIN(tenure) AS min_tenure, MAX(tenure) AS max_tenure,
  MIN(citytier) AS min_citytier, MAX(citytier) AS max_citytier,
  MIN(warehousetohome) AS min_warehouse, MAX(warehousetohome) AS max_warehouse,
  MIN(hourspendonapp) AS min_hours, MAX(hourspendonapp) AS max_hours,
  MIN(numberofdeviceregistered) AS min_devices, MAX(numberofdeviceregistered) AS max_devices,
  MIN(satisfactionscore) AS min_satisfaction, MAX(satisfactionscore) AS max_satisfaction,
  MIN(numberofaddress) AS min_address, MAX(numberofaddress) AS max_address,
  MIN(orderamounthikefromlastyear) AS min_hike, MAX(orderamounthikefromlastyear) AS max_hike,
  MIN(couponused) AS min_coupon, MAX(couponused) AS max_coupon,
  MIN(ordercount) AS min_ordercount, MAX(ordercount) AS max_ordercount,
  MIN(daysincelastorder) AS min_daysince, MAX(daysincelastorder) AS max_daysince,
  MIN(cashbackamount) AS min_cashback, MAX(cashbackamount) AS max_cashback
FROM ecommerce_clean;

#Checking the remaining numeric columns min/max ranges
SELECT
  MIN(hourspendonapp) AS min_hours, MAX(hourspendonapp) AS max_hours,
  MIN(numberofdeviceregistered) AS min_devices, MAX(numberofdeviceregistered) AS max_devices,
  MIN(satisfactionscore) AS min_satisfaction, MAX(satisfactionscore) AS max_satisfaction,
  MIN(numberofaddress) AS min_address, MAX(numberofaddress) AS max_address,
  MIN(orderamounthikefromlastyear) AS min_hike, MAX(orderamounthikefromlastyear) AS max_hike,
  MIN(couponused) AS min_coupon, MAX(couponused) AS max_coupon,
  MIN(ordercount) AS min_ordercount, MAX(ordercount) AS max_ordercount,
  MIN(daysincelastorder) AS min_daysince, MAX(daysincelastorder) AS max_daysince,
  MIN(cashbackamount) AS min_cashback, MAX(cashbackamount) AS max_cashback
FROM ecommerce_clean;

QUESTIONAIRE
1. Checking the overall churn rate
SELECT
  ROUND(100.0 * SUM(churn) / COUNT(*), 2) AS churn_rate_pct,
  COUNT(*) AS total_customers
FROM ecommerce_clean;

2. Checking churn rate by preferred login device
SELECT preferredlogindevice,
  COUNT(*) AS customers,
  SUM(churn) AS churned,
  ROUND(100.0 * SUM(churn) / COUNT(*), 2) AS churn_rate_pct
FROM ecommerce_clean
GROUP BY preferredlogindevice
ORDER BY churn_rate_pct DESC;

3. Checking churn rate by preferred payment mode
SELECT preferredpaymentmode,
  COUNT(*) AS customers,
  SUM(churn) AS churned,
  ROUND(100.0 * SUM(churn) / COUNT(*), 2) AS churn_rate_pct
FROM ecommerce_clean
GROUP BY preferredpaymentmode
ORDER BY churn_rate_pct DESC;

4. Checking churn rate by preferred order category
SELECT preferedordercat,
  COUNT(*) AS customers,
  SUM(churn) AS churned,
  ROUND(100.0 * SUM(churn) / COUNT(*), 2) AS churn_rate_pct
FROM ecommerce_clean
GROUP BY preferedordercat
ORDER BY churn_rate_pct DESC;

5. Checking churn rate by tenure bucket (new vs. long-standing customers)
SELECT
  CASE
    WHEN tenure < 3 THEN '0-2 months'
    WHEN tenure < 6 THEN '3-5 months'
    WHEN tenure < 12 THEN '6-11 months'
    ELSE '12+ months'
  END AS tenure_bucket,
  COUNT(*) AS customers,
  SUM(churn) AS churned,
  ROUND(100.0 * SUM(churn) / COUNT(*), 2) AS churn_rate_pct
FROM ecommerce_clean
GROUP BY tenure_bucket
ORDER BY MIN(tenure);

6. Checking churn rate by complaint status
SELECT complaint_status,
  COUNT(*) AS customers,
  SUM(churn) AS churned,
  ROUND(100.0 * SUM(churn) / COUNT(*), 2) AS churn_rate_pct
FROM ecommerce_clean
GROUP BY complaint_status;

7. Checking churn rate by satisfaction score
SELECT satisfactionscore,
  COUNT(*) AS customers,
  SUM(churn) AS churned,
  ROUND(100.0 * SUM(churn) / COUNT(*), 2) AS churn_rate_pct
FROM ecommerce_clean
GROUP BY satisfactionscore
ORDER BY satisfactionscore;







