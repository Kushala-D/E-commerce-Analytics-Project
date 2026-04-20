Create Database Ecommerce;
Use Ecommerce;

/* 1. Cumulative Revenue Over Time */
SELECT 
    CAST(order_purchase_timestamp AS DATE) AS order_date, 
    SUM(payment_value) AS daily_revenue,
    SUM(SUM(payment_value)) OVER (ORDER BY CAST(order_purchase_timestamp AS DATE)) AS cumulative_revenue
FROM Orders_table O
JOIN Payments_table P ON O.order_id = P.order_id
GROUP BY CAST(order_purchase_timestamp AS DATE)
ORDER BY order_date;

/* 2. Most Favored Product Categories & Sales Comparison */

SELECT 
    P.product_category_name, 
    COUNT(OI.order_id) AS total_orders, 
    SUM(OI.price) AS total_sales
FROM Order_items_table OI
JOIN Products_table P ON OI.product_id = P.product_id
GROUP BY P.product_category_name
ORDER BY total_sales DESC;

/* 3. Average Order Value (AOV) & Variation Across Categories & Payment Methods */

-- Overall AOV
SELECT 
    SUM(payment_value) / COUNT(DISTINCT O.order_id) AS avg_order_value
FROM Orders_table O
JOIN Payments_table P ON O.order_id = P.order_id;

-- AOV by Product Category
SELECT 
    P.product_category_name, 
    SUM(OI.price) / COUNT(DISTINCT OI.order_id) AS avg_order_value
FROM Order_items_table OI
JOIN Products_table P ON OI.product_id = P.product_id
GROUP BY P.product_category_name
ORDER BY avg_order_value DESC;

-- AOV by Payment Method
SELECT 
    P.payment_type, 
    SUM(P.payment_value) / COUNT(DISTINCT O.order_id) AS avg_order_value
FROM Orders_table O
JOIN Payments_table P ON O.order_id = P.order_id
GROUP BY P.payment_type
ORDER BY avg_order_value DESC;

/* 4. Number of Active Sellers & Their Trend Over Time */

SELECT 
    YEAR(O.order_purchase_timestamp) AS order_year, 
    COUNT(DISTINCT S.seller_id) AS active_sellers
FROM Orders_table O
JOIN Order_items_table OI ON O.order_id = OI.order_id
JOIN Sellers_table S ON OI.seller_id = S.seller_id
GROUP BY YEAR(O.order_purchase_timestamp)
ORDER BY order_year;

/* 5. Seller Ratings & Impact on Sales */

-- Breakdown of Seller Ratings
SELECT 
    R.review_score, 
    COUNT(*) AS review_count
FROM Customers_review_table R
GROUP BY R.review_score
ORDER BY R.review_score DESC;

-- Impact of Ratings on Sales Performance
SELECT 
    R.review_score, 
    COUNT(DISTINCT O.order_id) AS total_orders, 
    SUM(P.payment_value) AS total_revenue
FROM Customers_review_table R
JOIN Orders_table O ON R.order_id = O.order_id
JOIN Payments_table P ON O.order_id = P.order_id
GROUP BY R.review_score
ORDER BY R.review_score DESC;

/* 6. Repeat Customers & Their Sales Proportion */

WITH Repeat_Customers AS (
    SELECT customer_unique_id
    FROM Customers_table C
    JOIN Orders_table O ON C.customer_id = O.customer_id
    GROUP BY customer_unique_id
    HAVING COUNT(O.order_id) > 1
)
SELECT 
    COUNT(DISTINCT RC.customer_unique_id) AS repeat_customers,
    COUNT(DISTINCT O.customer_id) AS total_customers,
    CAST(COUNT(DISTINCT RC.customer_unique_id) AS FLOAT) / COUNT(DISTINCT O.customer_id) * 100 AS repeat_customer_percentage,
    SUM(P.payment_value) AS total_sales,
    (SELECT SUM(P2.payment_value) 
     FROM Orders_table O2
     JOIN Payments_table P2 ON O2.order_id = P2.order_id
     WHERE O2.customer_id IN (SELECT customer_id FROM Repeat_Customers)) AS repeat_customer_sales,
    CAST((SELECT SUM(P2.payment_value) 
          FROM Orders_table O2
          JOIN Payments_table P2 ON O2.order_id = P2.order_id
          WHERE O2.customer_id IN (SELECT customer_id FROM Repeat_Customers)) AS FLOAT) / SUM(P.payment_value) * 100 AS repeat_sales_percentage
FROM Orders_table O
JOIN Payments_table P ON O.order_id = P.order_id
LEFT JOIN Repeat_Customers RC ON O.customer_id = RC.customer_unique_id;

/* 7. Average Product Rating & Its Impact on Sales */

-- Average Rating per Product
SELECT 
    OI.product_id, 
    AVG(R.review_score) AS avg_rating,
    COUNT(OI.order_id) AS total_orders,
    SUM(OI.price) AS total_revenue
FROM Order_items_table OI
JOIN Customers_review_table R ON OI.order_id = R.order_id
GROUP BY OI.product_id
ORDER BY avg_rating DESC;

-- Overall Average Product Rating
SELECT AVG(review_score) AS overall_avg_rating FROM Customers_review_table;

/* 8. Order Cancellation Rate & Seller Impact */

-- Overall Cancellation Rate
SELECT 
    COUNT(CASE WHEN order_status = 'canceled' THEN 1 END) * 100.0 / COUNT(*) AS cancellation_rate
FROM Orders_table;

-- Cancellation Rate by Seller
SELECT 
    OI.seller_id, 
    COUNT(CASE WHEN O.order_status = 'canceled' THEN 1 END) * 100.0 / COUNT(O.order_id) AS seller_cancellation_rate,
    COUNT(O.order_id) AS total_orders,
    SUM(OI.price) AS total_revenue
FROM Orders_table O
JOIN Order_items_table OI ON O.order_id = OI.order_id
GROUP BY OI.seller_id
ORDER BY seller_cancellation_rate DESC;

/* 9. Top 3 Best-Selling Products & Their Sales Trends */

-- Identifying Top 3 Best-Selling Products
WITH Top_Products AS (
    SELECT TOP 3 
        product_id, 
        COUNT(order_id) AS total_orders, 
        SUM(price) AS total_revenue
    FROM Order_items_table
    GROUP BY product_id
    ORDER BY total_revenue DESC
)
-- Sales Trend Over Time for Top 3 Products
SELECT 
    CAST(O.order_purchase_timestamp AS DATE) AS order_date,
    OI.product_id, 
    COUNT(OI.order_id) AS daily_sales,
    SUM(OI.price) AS daily_revenue
FROM Order_items_table OI
JOIN Orders_table O ON OI.order_id = O.order_id
WHERE OI.product_id IN (SELECT product_id FROM Top_Products)
GROUP BY CAST(O.order_purchase_timestamp AS DATE), OI.product_id
ORDER BY order_date, daily_revenue DESC;


