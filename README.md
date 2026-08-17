# E-Commerce Marketplace Strategic Audit

**SQL Project | Microsoft SQL Server | Business Analysis, Strategic Diagnostics, Advanced SQL & Inventory Automation**

---

## Project Overview

This project performs a comprehensive strategic and operational audit of an e-commerce marketplace using **Microsoft SQL Server (MSSQL)**.

Rather than treating SQL as a collection of isolated exercises, the project approaches the marketplace as a business system. The analysis progresses from fundamental commercial and operational metrics to deeper marketplace diagnostics involving:

- Revenue and product performance
- Category contribution
- Customer behavior
- Seller concentration
- Customer segmentation
- Retention analysis
- Fulfillment performance
- Inventory risk
- Product profitability
- Cross-selling opportunities
- Database-level automation

The analysis is organized into **three analytical workstreams containing 22 SQL queries and database implementations**.

### Central Business Question

> **Is the marketplace generating sustainable and diversified value, or is its performance dependent on a small number of products, categories, sellers, and customers while operational inefficiencies create additional risk?**

---

# Business Objectives

The project aims to answer the following questions:

1. **Which products and categories generate the most marketplace revenue?**
2. **How concentrated is marketplace value across sellers?**
3. **Which customers contribute the most value and how can they be segmented?**
4. **Where are customer retention and cross-selling opportunities?**
5. **Which operational areas create shipping, payment, and inventory risks?**
6. **Which products offer stronger profitability or require inventory intervention?**
7. **How can database automation improve inventory synchronization?**

---

# Dataset

The analysis uses a relational e-commerce marketplace dataset consisting of nine tables:

| Table | Business Purpose |
|---|---|
| `customers` | Customer master data and geographic information |
| `orders` | Order-level transaction information |
| `order_items` | Products, quantities, and transaction-level pricing |
| `products` | Product catalog, pricing, and COGS |
| `category` | Product category information |
| `sellers` | Marketplace seller information |
| `inventory` | Product inventory and warehouse information |
| `payments` | Payment transaction status |
| `shipping` | Shipping provider, dispatch, and delivery information |

---

# Database Architecture

The database follows a relational marketplace model connecting customers, orders, products, sellers, inventory, payments, shipping, and categories.

The **Entity Relationship Diagram (ERD)** below illustrates the table schemas, key fields, and relationships used throughout the analysis.

<p align="center">
  <img src="ERD/marketplace_erd.png" alt="E-Commerce Marketplace Entity Relationship Diagram" width="100%">
</p>

### Core Relationship Structure

```text
customers
    │
    └──< orders >── sellers
           │
           └──< order_items >── products >── category
                                  │
                                  └── inventory

orders ─── payments
orders ─── shipping
```

The `orders` and `order_items` tables form the central transactional layer, connecting customer demand with products and sellers while linking operational information through payments, shipping, and inventory.

---

# Business Storyline

## 1. Establish Marketplace Performance

The first analytical layer establishes the commercial baseline of the marketplace.

The analysis evaluates:

- Top-selling products
- Revenue contribution by category
- Average order value
- Monthly sales trends
- Inactive customers
- Category performance by state
- Inventory stock levels
- Shipping delays
- Payment status distribution
- Top sellers

This establishes where marketplace value is being generated and highlights areas requiring deeper investigation.

---

## 2. Diagnose Marketplace Concentration

Marketplace performance can become strategically vulnerable when a disproportionate amount of value depends on a small number of sellers.

The project therefore uses **Pareto analysis** to calculate seller-level revenue and cumulative revenue contribution.

This helps answer:

> **How dependent is the marketplace on its highest-value sellers?**

---

## 3. Understand Customer Behavior

Customer analysis goes beyond basic order counts.

The project evaluates:

- Recency
- Frequency
- Monetary value
- New vs. returning customers
- Customer spending by state
- High-value customer groups
- Cross-category purchasing behavior

This creates a framework for understanding customer value and identifying potential growth opportunities.

---

## 4. Analyze Customer Retention

The cohort analysis identifies each customer's first purchase and tracks subsequent activity using the time difference from their first order.

The objective is to understand:

> **How effectively does the marketplace convert initial customers into repeat purchasers?**

---

## 5. Investigate Fulfillment Performance

Shipping analysis evaluates operational performance through:

- Orders taking more than three days to ship
- Average dispatch time by provider
- Carrier-specific Return-to-Origin (RTO) rates

This allows provider-level operational differences to be identified and investigated.

---

## 6. Identify Inventory Risk

Inventory analysis focuses on products requiring operational attention.

The project identifies:

- Low-stock products
- Dead stock
- Current inventory exposure
- Products with no recorded sales
- Opportunities for inventory synchronization

---

## 7. Analyze Product Profitability

Product profitability is evaluated using product price and Cost of Goods Sold (COGS).

The project calculates:

```text
Gross Margin % = ((Price - COGS) / Price) × 100
```

Products can then be ranked based on their estimated margin percentage.

---

## 8. Identify Cross-Selling Opportunities

The analysis identifies customers who have purchased from **Electronics** but have no recorded purchase from **Clothing**.

This creates a potential target group for:

- Cross-selling
- Personalized recommendations
- Category promotions
- Product bundling

---

# SQL Query Portfolio

The complete analysis is divided into three sections:

| Section | Queries | Focus |
|---|---:|---|
| **Basic Business Problems** | 1–10 | Commercial and operational tracking |
| **Advanced Strategic Audit** | 11–20 | Marketplace diagnostics and strategic analysis |
| **Automation** | 21–22 | Inventory synchronization and sales processing |

The complete executable SQL script is available here:

**[`MARKETPLACE_STRATEGIC_AUDIT.sql`](SQL/MARKETPLACE_STRATEGIC_AUDIT.sql)**

---

# Section 1 — Basic Business Problems

## Query 1 — Top 10 Selling Products by Revenue

Identifies the ten products generating the highest revenue and their total units sold.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
SELECT TOP 10 
    p.product_name, 
    SUM(oi.quantity) as total_units, 
    SUM(oi.quantity * oi.price_per_unit) as total_revenue
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC;
```

</details>

---

## Query 2 — Revenue Contribution by Category

Calculates category-level revenue and each category's percentage contribution to total marketplace revenue.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
SELECT 
    c.category_name,
    SUM(oi.quantity * oi.price_per_unit) as revenue,
    CAST(SUM(oi.quantity * oi.price_per_unit) * 100.0 / SUM(SUM(oi.quantity * oi.price_per_unit)) OVER() AS DECIMAL(10,2)) as pct_contribution
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
JOIN category c ON p.category_id = c.category_id
GROUP BY c.category_name
ORDER BY revenue DESC;
```

</details>

---

## Query 3 — Average Order Value for Frequent Customers

Calculates Average Order Value (AOV) for customers with more than five orders.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
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
```

</details>

---

## Query 4 — Monthly Sales Trend

Tracks monthly revenue and compares each month with the preceding month using the `LAG()` window function.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
SELECT 
    YEAR(order_date) as yr, 
    MONTH(order_date) as mth, 
    SUM(quantity * price_per_unit) as monthly_revenue,
    LAG(SUM(quantity * price_per_unit)) OVER(ORDER BY YEAR(order_date), MONTH(order_date)) as prev_month_rev
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY YEAR(order_date), MONTH(order_date);
```

</details>

---

## Query 5 — Customers with Zero Purchases

Identifies registered customers who have no recorded purchase activity.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
SELECT c.customer_id, c.first_name, c.last_name
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;
```

</details>

---

## Query 6 — Least-Selling Category by State

Uses `RANK()` to identify the lowest-revenue category within each customer state.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
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
```

</details>

---

## Query 7 — Inventory Stock Alerts

Identifies products with fewer than 10 units of available inventory.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
SELECT p.product_name, i.stock, i.warehouse_id
FROM inventory i
JOIN products p ON i.product_id = p.product_id
WHERE i.stock < 10;
```

</details>

---

## Query 8 — Shipping Delay Analysis

Identifies orders where shipping takes more than three days from the order date.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
SELECT o.order_id, o.order_date, s.shipping_date, DATEDIFF(day, o.order_date, s.shipping_date) as delay
FROM orders o
JOIN shipping s ON o.order_id = s.order_id
WHERE DATEDIFF(day, o.order_date, s.shipping_date) > 3;
```

</details>

---

## Query 9 — Payment Status Distribution

Analyzes payment-status distribution and calculates the percentage represented by each status.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
SELECT 
    payment_status, 
    COUNT(*) as count, 
    CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(10,2)) as pct
FROM payments
GROUP BY payment_status;
```

</details>

---

## Query 10 — Top 5 Sellers by Revenue & Success Rate

Ranks the top five sellers by revenue and calculates their order success rate.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
SELECT TOP 5 
    s.seller_name,
    SUM(oi.quantity * oi.price_per_unit) as total_rev,
    CAST(SUM(CASE WHEN o.order_status = 'Completed' THEN 1 ELSE 0 END) * 100.0 / COUNT(o.order_id) AS DECIMAL(10,2)) as success_rate
FROM sellers s
JOIN orders o ON s.seller_id = o.seller_id
JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY s.seller_name
ORDER BY total_rev DESC;
```

</details>

---

# Section 2 — Advanced Strategic Audit

## Query 11 — Seller Concentration / Pareto Analysis

Measures cumulative seller revenue to understand marketplace concentration.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
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
```

</details>

---

## Query 12 — RFM Customer Segmentation

Calculates customer **Recency, Frequency, and Monetary Value** and assigns quintile-based RFM scores.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
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
```

</details>

---

## Query 13 — Month-1 Cohort Retention

Tracks customer activity based on the number of months elapsed since the customer's first recorded order.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
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
```

</details>

---

## Query 14 — Carrier-Specific RTO Rates

Compares Return-to-Origin rates across shipping providers.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
SELECT 
    [shipping providers], 
    COUNT(*) as total_shipments,
    CAST(SUM(CASE WHEN delivery_status = 'Returned' THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS DECIMAL(10,2)) as rto_rate
FROM shipping
GROUP BY [shipping providers];
```

</details>

---

## Query 15 — Dead Stock Identification

Identifies products that currently hold inventory but have no recorded sales.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
SELECT p.product_name, i.stock, p.price * i.stock as dead_stock_value
FROM products p
JOIN inventory i ON p.product_id = i.product_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.order_id IS NULL;
```

</details>

---

## Query 16 — Cross-Sell Opportunity

Identifies customers who purchased Electronics but have no recorded Clothing purchase.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
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
```

</details>

---

## Query 17 — Product Profit Margin Ranking

Ranks products according to their estimated gross-margin percentage.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
SELECT p.product_name, ((p.price - p.cogs) / p.price) * 100 as margin_pct
FROM products p
ORDER BY margin_pct DESC;
```

</details>

---

## Query 18 — Returning vs. New Customer Sales Mix

Separates customers into new and returning groups and compares their revenue contribution.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
WITH CustomerType AS (
    SELECT customer_id, CASE WHEN COUNT(order_id) > 1 THEN 'Returning' ELSE 'New' END as type
    FROM orders GROUP BY customer_id
)
SELECT ct.type, SUM(oi.quantity * oi.price_per_unit) as revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN CustomerType ct ON o.customer_id = ct.customer_id
GROUP BY ct.type;
```

</details>

---

## Query 19 — Average Days to Ship by Provider

Calculates average dispatch time for each shipping provider.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
SELECT [shipping providers], AVG(DATEDIFF(day, o.order_date, s.shipping_date)) as avg_days
FROM orders o JOIN shipping s ON o.order_id = s.order_id
GROUP BY [shipping providers];
```

</details>

---

## Query 20 — Top 5 Customers by State

Uses `DENSE_RANK()` with partitioning by state to identify the highest-spending customers within each state.

<details>
<summary><strong>View SQL Query</strong></summary>

```sql
SELECT * FROM (
    SELECT c.state, c.first_name, SUM(oi.quantity * oi.price_per_unit) as spend,
    DENSE_RANK() OVER(PARTITION BY c.state ORDER BY SUM(oi.quantity * oi.price_per_unit) DESC) as rnk
    FROM customers c JOIN orders o ON c.customer_id = o.customer_id
    JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY c.state, c.first_name
) t WHERE rnk <= 5;
```

</details>

---

# Section 3 — Automation

## Query 21 — Real-Time Inventory Synchronization Trigger

Creates a SQL Server trigger that automatically reduces inventory when a new order item is inserted.

### Operational Flow

```text
New Order Item
      ↓
AFTER INSERT Trigger
      ↓
Identify Product
      ↓
Match Inventory
      ↓
Reduce Available Stock
```

<details>
<summary><strong>View SQL Trigger</strong></summary>

```sql
GO

CREATE TRIGGER trg_sync_inventory ON order_items AFTER INSERT AS
BEGIN
    UPDATE inv SET inv.stock = inv.stock - i.quantity
    FROM inventory inv JOIN inserted i ON inv.product_id = i.product_id;
END;
GO
```

</details>

---

## Query 22 — Stored Procedure for Processing a New Sale

Creates a stored procedure for processing a new order item.

The inventory synchronization trigger automatically handles the corresponding stock update.

### Operational Flow

```text
Process Sale
      ↓
Stored Procedure
      ↓
Insert Order Item
      ↓
Inventory Trigger
      ↓
Inventory Updated
```

<details>
<summary><strong>View SQL Procedure</strong></summary>

```sql
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
```

</details>

---

# Technical Approach

The project demonstrates practical application of:

- **Microsoft SQL Server / T-SQL**
- Multi-table joins
- Aggregations
- Subqueries
- Common Table Expressions (CTEs)
- Window functions
- `RANK()`
- `DENSE_RANK()`
- `NTILE()`
- `LAG()`
- Conditional aggregation
- `CASE WHEN`
- Date functions
- Pareto analysis
- RFM segmentation
- Cohort analysis
- Customer segmentation
- Inventory analytics
- Seller analytics
- Fulfillment analytics
- Product profitability analysis
- SQL Server triggers
- Stored procedures

---

# Strategic Analysis Framework

```text
                    E-COMMERCE MARKETPLACE
                            │
             ┌──────────────┼──────────────┐
             │              │              │
        COMMERCIAL       CUSTOMER       OPERATIONAL
         ANALYSIS        ANALYSIS        ANALYSIS
             │              │              │
       ┌─────┼─────┐    ┌───┼────┐     ┌───┼────┐
       │     │     │    │   │    │     │   │    │
    Product Category Seller RFM Cohort Cross-Sell
                                             │
                                      Shipping / Payment
                                      Inventory
             │              │              │
             └──────────────┼──────────────┘
                            │
                     STRATEGIC AUDIT
                            │
                            ↓
                  BUSINESS OPPORTUNITIES
                            │
                            ↓
                  DATABASE AUTOMATION
```

---

# Business Opportunities

The analysis framework supports decision-making across four major areas:

### Revenue & Marketplace Concentration

Identify dependence on specific products, categories, sellers, or customer groups.

### Customer Growth & Retention

Use RFM, cohort, and new-vs-returning customer analysis to identify opportunities for customer retention and growth.

### Operational Performance

Use shipping, payment, and inventory analysis to identify potential process inefficiencies and operational risks.

### Inventory & Profitability

Identify low-stock products, dead stock, and products with stronger estimated margins to support assortment and inventory decisions.

---

# Repository Structure

```text
E-Commerce-Marketplace-Strategic-Audit/
│
├── Dataset/
│   ├── category.csv
│   ├── customers.csv
│   ├── inventory.csv
│   ├── order_items.csv
│   ├── orders.csv
│   ├── payments.csv
│   ├── products.csv
│   ├── sellers.csv
│   └── shipping.csv
│
├── ERD/
│   └── marketplace_erd.png
│
├── SQL/
│   └── MARKETPLACE_STRATEGIC_AUDIT.sql
│
└── README.md
```

---

# Author

**Sanchit Duggal**

**Project:** E-Commerce Marketplace Strategic Audit  
**Database:** Microsoft SQL Server / T-SQL
