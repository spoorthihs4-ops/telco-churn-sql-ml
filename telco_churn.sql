-- Telco Customer Churn: normalised schema and analytical queries (SQLite)
-- Extracted from notebooks/01_data_and_sql_pipeline.ipynb

-- ===== Schema =====
CREATE TABLE customers (
        customerID TEXT PRIMARY KEY,
        gender TEXT, SeniorCitizen INT, Partner TEXT,
        Dependents TEXT, tenure INT, Churn TEXT);

CREATE TABLE services (
        serviceID INTEGER PRIMARY KEY,
        customerID TEXT UNIQUE,
        PhoneService TEXT, MultipleLines TEXT,
        InternetService TEXT, OnlineSecurity TEXT,
        OnlineBackup TEXT, DeviceProtection TEXT,
        TechSupport TEXT, StreamingTV TEXT,
        StreamingMovies TEXT,
        FOREIGN KEY(customerID) REFERENCES customers(customerID));

CREATE TABLE contracts (
        contractID INTEGER PRIMARY KEY,
        customerID TEXT UNIQUE,
        Contract TEXT, PaperlessBilling TEXT,
        PaymentMethod TEXT,
        FOREIGN KEY(customerID) REFERENCES customers(customerID));

CREATE TABLE billing (
        billingID INTEGER PRIMARY KEY,
        customerID TEXT UNIQUE,
        MonthlyCharges REAL, TotalCharges REAL,
        FOREIGN KEY(customerID) REFERENCES customers(customerID));

-- ===== Analytical queries =====
-- Query 1: SELECT subsets of data (with filtering)
SELECT customerID, tenure, Churn, gender, SeniorCitizen
FROM customers
WHERE tenure > 12 AND Churn = 'No'
ORDER BY tenure DESC
LIMIT 15;

-- Query 2: JOIN tables
SELECT c.customerID, c.tenure, c.Churn,
       b.MonthlyCharges, b.TotalCharges,
       s.InternetService, s.OnlineSecurity,
       ct.Contract, ct.PaymentMethod
FROM customers c
INNER JOIN billing b ON c.customerID = b.customerID
LEFT JOIN services s ON c.customerID = s.customerID
LEFT JOIN contracts ct ON c.customerID = ct.customerID
WHERE c.tenure > 6
ORDER BY c.tenure DESC
LIMIT 15;

-- Query 3: GROUP BY with Aggregation
SELECT
    c.Churn,
    ct.Contract,
    s.InternetService,
    COUNT(*) as Total_Customers,
    ROUND(AVG(c.tenure), 1) as Avg_Tenure_Months,
    ROUND(AVG(b.MonthlyCharges), 2) as Avg_Monthly_Charges,
    ROUND(SUM(b.TotalCharges), 2) as Total_Revenue,
    ROUND(AVG(b.TotalCharges), 2) as Avg_Total_Charges
FROM customers c
INNER JOIN billing b ON c.customerID = b.customerID
LEFT JOIN contracts ct ON c.customerID = ct.customerID
LEFT JOIN services s ON c.customerID = s.customerID
GROUP BY c.Churn, ct.Contract, s.InternetService
ORDER BY Total_Customers DESC;

-- Query 4: FILTER, GROUP, AGGREGATE (all requirements combined)
SELECT
    c.SeniorCitizen,
    c.Partner,
    c.Dependents,
    ct.PaymentMethod,
    COUNT(*) as Customer_Count,
    ROUND(AVG(c.tenure), 1) as Avg_Tenure,
    ROUND(AVG(b.MonthlyCharges), 2) as Avg_Monthly_Charges,
    ROUND(SUM(CASE WHEN c.Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) as Churn_Rate_Percent
FROM customers c
INNER JOIN billing b ON c.customerID = b.customerID
LEFT JOIN contracts ct ON c.customerID = ct.customerID
WHERE b.MonthlyCharges > 50  -- FILTER
GROUP BY c.SeniorCitizen, c.Partner, c.Dependents, ct.PaymentMethod  -- GROUP
HAVING COUNT(*) > 5  -- Additional filter on groups
ORDER BY Churn_Rate_Percent DESC;  -- AGGREGATE (ORDER BY uses aggregated column)

