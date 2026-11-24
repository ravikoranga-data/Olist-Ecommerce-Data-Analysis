--1. Overall Business KPIs (Delivered Orders)
SELECT 
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS total_unique_customers,
    ROUND(SUM(p.payment_value)::numeric, 2) AS total_revenue,
    ROUND(AVG(p.payment_value)::numeric, 2) AS avg_payment_value
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered';


--2. Monthly Revenue Trend
SELECT 
    TO_CHAR(o.order_purchase_timestamp, 'YYYY-MM') AS order_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(p.payment_value)::numeric, 2) AS monthly_revenue
FROM orders o
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY order_month
ORDER BY order_month;


--3. Top 10 product Catagories
SELECT 
    p.product_category_name_english AS category,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    ROUND(SUM(oi.price)::numeric, 2) AS total_sales
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY category
ORDER BY total_sales DESC
LIMIT 10;

--4.Delivery Speed vs Review Score
SELECT 
    CASE 
        WHEN o.order_delivered_customer_date <= o.order_estimated_delivery_date THEN 'On-Time Delivery'
        ELSE 'Late Delivery'
    END AS delivery_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(r.review_score)::numeric, 2) AS avg_review_score
FROM orders o
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY delivery_status;


-- 5. Top 5 Customer States by Revenue
SELECT 
    c.customer_state AS state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(SUM(p.payment_value)::numeric, 2) AS total_revenue
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY state
ORDER BY total_revenue DESC
LIMIT 5;

-- 5B. Payment Methods Breakdown
SELECT 
    payment_type,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(payment_value)::numeric, 2) AS total_revenue
FROM order_payments
GROUP BY payment_type
ORDER BY total_revenue DESC;

-- 6. Customer Retention Analysis
WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS order_count
    FROM orders o
    JOIN customers c ON o.customer_id = c.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
)
SELECT 
    CASE WHEN order_count = 1 THEN 'One-Time Buyer' ELSE 'Repeat Buyer' END AS customer_type,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage_share
FROM customer_orders
GROUP BY customer_type;

-- 7. Payment Method Revenue Share %
SELECT 
    payment_type,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(SUM(payment_value)::numeric, 2) AS total_revenue,
    ROUND(SUM(payment_value)::numeric * 100.0 / SUM(SUM(payment_value)::numeric) OVER(), 2) AS revenue_share_pct
FROM order_payments
GROUP BY payment_type
ORDER BY total_revenue DESC;