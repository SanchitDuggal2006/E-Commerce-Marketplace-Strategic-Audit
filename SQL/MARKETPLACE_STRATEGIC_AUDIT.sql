-- ==========================================================
-- E-COMMERCE MARKETPLACE STRATEGIC AUDIT: COMPREHENSIVE SCRIPT
-- ==========================================================
-- Database: MSSQL (SQL Server)
-- Total Queries: 25+ (Basic Business Problems + Advanced Strategic Audit)

-- ----------------------------------------------------------
-- SECTION 1: BASIC BUSINESS PROBLEMS (Operational Tracking)
-- ----------------------------------------------------------

-- 1. Top 10 Selling Products by Revenue
SELECT TOP 10 
    p.product_name, 
    SUM(oi.quantity) as total_units, 
    SUM(oi.quantity * oi.price_per_unit) as total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC;

-- 2. Revenue Contribution by Category (%)
SELECT 
    c.category_name,
    SUM(oi.quantity * oi.price_per_unit) as revenue,
    CAST(SUM(oi.quantity * oi.price_per_unit) * 100.0 / SUM(SUM(oi.quantity * oi.price_per_unit)) OVER() AS DECIMAL(10,2)) as pct_contribution
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN category c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY revenue DESC;

-- 3. Average Order Value (AOV) for Frequent Customers (>5 orders)
SELECT 
    customer_id,
    COUNT(order_id) as total_orders,
    AVG(order_total) as AOV
FROM (
    SELECT o.customer_id, o.order_id, SUM(oi.quantity * oi.price_per_unit) as order_total
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY o.customer_id, o.order_id
) t
GROUP BY customer_id
HAVING COUNT(order_id) > 5;

-- 4. Monthly Sales Trend (YoY Comparison)
SELECT 
    YEAR(order_date) as yr, 
    MONTH(order_date) as mth, 
    SUM(quantity * price_per_unit) as monthly_revenue,
    LAG(SUM(quantity * price_per_unit)) OVER(ORDER BY YEAR(order_date), MONTH(order_date)) as prev_month_rev
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY YEAR(order_date), MONTH(order_date);

-- 5. Customers with Zero Purchases (Registered but Inactive)
SELECT c.customer_id, c.first_name, c.last_name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- 6. Least Selling Category by State
WITH StateCatSales AS (
    SELECT 
        c.state, 
        cat.category_name, 
        SUM(oi.quantity * oi.price_per_unit) as rev,
        RANK() OVER(PARTITION BY c.state ORDER BY SUM(oi.quantity * oi.price_per_unit) ASC) as rnk
    FROM customers c
    JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
    JOIN category cat ON p.category_id = cat.category_id
    GROUP BY c.state, cat.category_name
)
SELECT * FROM StateCatSales WHERE rnk = 1;

-- 7. Inventory Stock Alerts (Low Stock < 10 units)
SELECT p.product_name, i.stock, i.warehouse_id
FROM inventory i
JOIN products p ON i.product_id = p.product_id
WHERE i.stock < 10;

-- 8. Shipping Delay Analysis (> 3 days)
SELECT o.order_id, o.order_date, s.shipping_date, DATEDIFF(day, o.order_date, s.shipping_date) as delay
FROM orders o
JOIN shipping s ON o.order_id = s.order_id
WHERE DATEDIFF(day, o.order_date, s.shipping_date) > 3;

-- 9. Payment Success Rate by Mode
SELECT 
    payment_status, 
    COUNT(*) as count, 
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(10,2)) as pct
FROM payments
GROUP BY payment_status;

-- 10. Top 5 Sellers by Revenue & Success Rate
SELECT TOP 5 
    s.seller_name,
    SUM(oi.quantity * oi.price_per_unit) as total_rev,
    CAST(SUM(CASE WHEN o.order_status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id) AS DECIMAL(10,2)) as success_rate
FROM sellers s
JOIN orders o ON s.seller_id = o.seller_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY s.seller_name
ORDER BY total_rev DESC;

-- ----------------------------------------------------------
-- SECTION 2: ADVANCED STRATEGIC AUDIT (Marketplace Diagnostics)
-- ----------------------------------------------------------

-- 11. Seller Concentration (Pareto Analysis)
WITH SellerRev AS (
    SELECT seller_id, SUM(quantity * price_per_unit) as rev
    FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY seller_id
),
SellerPareto AS (
    SELECT *, SUM(rev) OVER(ORDER BY rev DESC) as cum_rev, SUM(rev) OVER() as total_rev
    FROM SellerRev
)
SELECT *, (cum_rev / total_rev) * 100 as cum_pct FROM SellerPareto;

-- 12. RFM Customer Segmentation
WITH RFM AS (
    SELECT 
        customer_id,
        DATEDIFF(day, MAX(order_date), (SELECT MAX(order_date) FROM orders)) as recency,
        COUNT(order_id) as frequency,
        SUM(quantity * price_per_unit) as monetary
    FROM orders o JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY customer_id
)
SELECT *, 
    NTILE(5) OVER(ORDER BY recency ASC) as r_score,
    NTILE(5) OVER(ORDER BY frequency DESC) as f_score,
    NTILE(5) OVER(ORDER BY monetary DESC) as m_score
FROM RFM;

-- 13. Month-1 Cohort Retention (%)
WITH FirstOrders AS (
    SELECT customer_id, MIN(order_date) as first_date FROM orders GROUP BY customer_id
),
Activity AS (
    SELECT o.customer_id, DATEDIFF(month, f.first_date, o.order_date) as mth_diff
    FROM orders o JOIN FirstOrders f ON o.customer_id = f.customer_id
)
SELECT mth_diff, COUNT(DISTINCT customer_id) as users
FROM Activity 
GROUP BY mth_diff;

-- 14. Carrier-Specific RTO (Return-to-Origin) Rates
SELECT 
    [shipping providers], 
    COUNT(*) as total_shipments,
    CAST(SUM(CASE WHEN delivery_status = 'Returned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(10,2)) as rto_rate
FROM shipping
GROUP BY [shipping providers];

-- 15. Dead Stock Identification (Stagnant Inventory)
SELECT p.product_name, i.stock, p.price * i.stock as dead_stock_value
FROM products p
JOIN inventory i ON p.product_id = i.product_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.order_id IS NULL;

-- 16. Cross-Sell Opportunity (Electronics but no Clothing)
SELECT DISTINCT customer_id FROM orders o 
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE p.category_id = 1 -- Electronics
AND customer_id NOT IN (
    SELECT customer_id FROM orders o2 
    JOIN order_items oi2 ON o2.order_id = oi2.order_id
    JOIN products p2 ON oi2.product_id = p2.product_id
    WHERE p2.category_id = 2 -- Clothing
);

-- 17. Product Profit Margin Ranking
SELECT p.product_name, ((p.price - p.cogs) / p.price) * 100 as margin_pct
FROM products p
ORDER BY margin_pct DESC;

-- 18. Returning vs. New Customer Sales Mix
WITH CustomerType AS (
    SELECT customer_id, CASE WHEN COUNT(order_id) > 1 THEN 'Returning' ELSE 'New' END as type
    FROM orders GROUP BY customer_id
)
SELECT ct.type, SUM(oi.quantity * oi.price_per_unit) as revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN CustomerType ct ON o.customer_id = ct.customer_id
GROUP BY ct.type;

-- 19. Average Days to Ship by Provider
SELECT [shipping providers], AVG(DATEDIFF(day, o.order_date, s.shipping_date)) as avg_days
FROM orders o JOIN shipping s ON o.order_id = s.order_id
GROUP BY [shipping providers];

-- 20. Top 5 Customers by State (Window Function)
SELECT * FROM (
    SELECT c.state, c.first_name, SUM(oi.quantity * oi.price_per_unit) as spend,
    DENSE_RANK() OVER(PARTITION BY c.state ORDER BY SUM(oi.quantity * oi.price_per_unit) DESC) as rnk
    FROM customers c JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.state, c.first_name
) t WHERE rnk <= 5;

-- ----------------------------------------------------------
-- SECTION 3: AUTOMATION (Triggers & Procedures)
-- ----------------------------------------------------------

-- 21. Real-Time Inventory Sync Trigger
GO
CREATE TRIGGER trg_sync_inventory ON order_items AFTER INSERT AS
BEGIN
    UPDATE inv SET inv.stock = inv.stock - i.quantity
    FROM inventory inv JOIN inserted i ON inv.product_id = i.product_id;
END;
GO

-- 22. Stored Procedure: Process New Sale
GO
CREATE PROCEDURE sp_ProcessSale 
    @OrderID INT, @ProdID INT, @Qty INT, @Price FLOAT
AS
BEGIN
    INSERT INTO order_items (order_id, product_id, quantity, price_per_unit)
    VALUES (@OrderID, @ProdID, @Qty, @Price);
    -- Trigger will handle inventory sync automatically
END;
GO
