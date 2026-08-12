
# E-Commerce Marketplace Intelligence and Operational Audit

**Project type:** SQL business analysis and database automation  
**SQL environment:** Microsoft SQL Server (T-SQL)  
**Dataset:** 9 related tables, 21,629 orders, 898 customers, 765 products, and 54 sellers  
**Analysis period:** January 1, 2020 to July 30, 2024

## Overview

This project evaluates the health of an e-commerce marketplace using SQL. The objective is to move beyond basic sales reporting and answer four business questions:

1. How dependent is the marketplace on particular categories, sellers, and customers?
2. Are returns associated with fulfillment speed, or are they concentrated among particular carriers?
3. Are customers returning after their first purchase, and which customer segments should receive retention attention?
4. Which products represent inventory risk through slow movement, dead stock, or limited days of supply?

The analysis combines data validation, revenue and margin calculations, concentration analysis, customer segmentation, cohort retention, fulfillment diagnostics, inventory screening, and automated stock synchronization.

## Executive Findings

The dataset contains **21,629 orders and 21,629 order-item records**. Observed order-line value, calculated as `quantity * price_per_unit`, is **$12.64 million**. Because the data contains completed, returned, cancelled, and in-progress orders, this figure is reported as observed order-line value rather than net revenue.

| Area | Verified finding | Business interpretation |
|---|---:|---|
| Category concentration | Electronics represents **89.7%** of observed order-line value. | The marketplace is highly exposed to demand, pricing, and supply changes in one category. |
| Seller concentration | The top five of 54 sellers account for **65.5%** of observed order-line value. | Seller diversification is relevant because a small group controls a large share of marketplace value. |
| Customer concentration | The top 68 of 686 customers with orders account for **36.4%** of observed order-line value. | A relatively small group of high-value customers deserves targeted retention analysis. |
| Customer retention | Weighted Month-1 cohort retention is **34.2%**, using customers with a first purchase and a recorded activity month one month later. | The first-to-second-purchase stage is an important lifecycle point for retention testing. |
| Fulfillment returns | The observed return-status rate is **79.1% for BlueDart, 21.5% for DHL, and 0.0% for FedEx**. | Carrier performance should be investigated before treating returns as a general product or delivery-speed problem. |
| Delivery speed | Average dispatch time is approximately **3.0 days** for both delivered and returned shipments. | The dataset does not show a meaningful relationship between dispatch delay and return status. |
| Inventory health | **15 products** have no recorded sales and represent **$13,770.93** of inventory value at listed price multiplied by current stock. | These products are candidates for review, clearance, or assortment decisions. |

The carrier result is treated as an **observed association, not proof of causation**. The difference is unusually large, so a production analyst should validate carrier assignment, status definitions, and operational processes before recommending a contract or volume change.

## Business Narrative

The project follows a marketplace health-audit narrative rather than presenting a flat list of SQL exercises.

The first stage establishes where marketplace value is generated. Category, seller, and customer concentration analysis shows that the platform is not evenly distributed: Electronics contributes most of the observed value, a small seller group contributes a large share of sales, and a small set of customers contributes a significant share of value. This creates a measurable diversification and retention risk.

The second stage examines the customer lifecycle. RFM analysis ranks customers by recency, frequency, and monetary value, while cohort analysis measures whether customers return after their first purchase. The purpose is to identify high-value customers for retention activity and to locate the stage where customer engagement weakens.

The third stage investigates fulfillment performance. Rather than assuming that slow shipping causes returns, the analysis compares dispatch time and return status and then breaks return rates down by carrier. In this dataset, returned and delivered shipments have nearly identical average dispatch times, while the carrier-level return rates differ substantially. This narrows the operational question from a general returns problem to a carrier-data and process investigation.

The final stage reviews inventory. The dataset provides a current inventory snapshot, not a historical inventory ledger. Therefore, the project uses defensible screening metrics: products with no recorded sales, current inventory value, and days of supply based on historical sales velocity. These metrics support review and prioritization; they do not claim to estimate realized lost sales.

## Analytical Workstreams

### 1. Data Validation and Metric Definitions

The raw files are loaded into relational tables and checked for row counts, duplicate keys, missing relationships, status values, date ranges, and inconsistent text such as trailing spaces in delivery statuses. Revenue is calculated dynamically because `order_items` does not contain a stored `total_sale` column.

The core line-value definition is:

```sql
quantity * price_per_unit
```

All time-based analysis is anchored to the latest order date in the dataset rather than the system date. This prevents a static historical dataset from being incorrectly labeled inactive when the query is executed later.

### 2. Revenue, Margin, and Concentration

The revenue workstream calculates observed order-line value, category contribution, product performance, product-level gross margin, and seller contribution. Window functions are used to rank sellers and calculate cumulative value shares for Pareto analysis.

The main business questions are:

- Which categories and products generate the most value?
- Which categories combine high value with strong gross margin?
- How much value is controlled by the top sellers?
- Is marketplace growth diversified or dependent on a small number of participants?

### 3. Customer Lifecycle, RFM, and Cohort Retention

Customer analysis uses order history and order-line value to calculate:

- **Recency:** Days since each customer's most recent order, measured from the dataset's maximum order date.
- **Frequency:** Number of distinct orders placed by each customer.
- **Monetary value:** Total observed order-line value associated with each customer.
- **Cohort retention:** The percentage of customers from each first-order month who are active in later months.

`NTILE` is used to create RFM scores, and common segments such as Champions, Loyal Customers, At Risk, and Hibernating Customers can be defined from the combined score. The output is intended to support targeted retention hypotheses, not to claim that a campaign has already improved retention.

### 4. Fulfillment and Return Diagnostics

Shipping performance is analyzed using `order_date`, `shipping_date`, `delivery_status`, and `shipping_providers`. The analysis calculates dispatch days, delivery-status mix, carrier-level return-status rates, and return rates across dispatch-time buckets.

The central hypothesis is:

> Are returns primarily associated with slower dispatch, or are they concentrated by carrier?

The dataset shows similar average dispatch time for delivered and returned shipments, while return-status rates vary by carrier. This finding supports a targeted data-quality and operations review. It does not justify claiming that a carrier is definitively the sole cause of returns without additional operational data.

### 5. Inventory Health and Working-Capital Screening

Inventory analysis joins the current inventory snapshot to products and historical order-item demand. It calculates:

- Current stock by product.
- Products with no recorded sales.
- Inventory value proxy: `price * stock`.
- Historical average daily units sold.
- Approximate days of supply at the observed historical sales rate.
- Low-stock alerts using a configurable threshold.

The data contains one warehouse and no historical stock snapshots. Consequently, the project does not claim to measure actual stockout events, inventory turnover over time, or realized lost revenue. It presents a prioritized screening model for replenishment and assortment review.

### 6. Inventory Automation

The project includes a SQL trigger that decrements inventory when a new order-item record is inserted. This demonstrates how database logic can support operational consistency.

For a production implementation, the trigger should also validate available stock, prevent negative inventory, handle multi-row inserts correctly, and define how cancellations, returns, and order-status changes reverse or adjust stock. The current dataset supports demonstrating the synchronization pattern, but it does not contain an inventory-movement history for auditing every stock change.

## Technical Skills Demonstrated

| Skill | Application in the project |
|---|---|
| Relational data modeling | Connected customers, orders, order items, products, categories, sellers, payments, shipping, and inventory. |
| Joins and aggregations | Built product, category, seller, customer, carrier, and inventory metrics. |
| Common table expressions | Structured multi-step retention, RFM, Pareto, and inventory calculations. |
| Window functions | Used `RANK`, `DENSE_RANK`, `NTILE`, `LAG`, and cumulative sums for segmentation and comparison. |
| Data cleaning | Normalized status text, handled missing shipping records, and calculated derived revenue fields. |
| SQL automation | Implemented an inventory synchronization trigger and a sale-processing procedure. |
| Business interpretation | Converted analytical outputs into recommendations for diversification, retention, carrier review, and inventory action. |

## Data Quality Notes and Scope Boundaries

The dataset contains nine CSV-backed tables. The original project description referred to eight tables, but the supplied files include `category`, `customers`, `inventory`, `order_items`, `orders`, `payments`, `products`, `sellers`, and `shipping`.

The order date range is January 1, 2020 through July 30, 2024. The shipping table contains 21,141 records compared with 21,629 orders; the difference corresponds to orders without a shipping record, primarily cancelled orders. Delivery-status values include `Delivered`, `Returned ` with a trailing space, and `Shipped`, so status trimming is required before analysis.

The data contains one inventory warehouse, and the minimum recorded stock is one unit; there are no rows with zero stock. Inventory is therefore a current snapshot rather than a historical stock ledger. Also, every order has one corresponding order-item row in the supplied data. The schema can support multiple items per order, but this specific extract does not provide a broad basket structure for reliable product-bundling or cross-sell analysis.

The dataset does not include customer registration dates, discounts, promotions, shipping costs, payment amounts, customer acquisition costs, seller fees, delivery destination geography, or a carrier service-level agreement. Therefore, the project does not claim to calculate CAC, true CLTV, net profit after logistics, price elasticity, shipping cost savings, or causal effects of promotions.

## Recommended Actions from the Analysis

The findings support four practical next steps. First, review category and seller concentration and define diversification targets for categories and sellers outside the current concentration. Second, audit carrier-level return-status patterns, including status definitions, carrier assignment, geography, and operational records, before reallocating volume. Third, use RFM and cohort outputs to design a first-to-second-order retention experiment and measure subsequent cohort performance. Fourth, review the 15 no-sale products for clearance, assortment, or listing-quality decisions and use the days-of-supply screen as a replenishment-prioritization tool.

These are recommendations for investigation or experimentation. They are not claims of realized business savings because the dataset contains no intervention or post-intervention period.

## Repository Structure

```text
.
├── README.md
├── data/
│   ├── category.csv
│   ├── customers.csv
│   ├── inventory.csv
│   ├── order_items.csv
│   ├── orders.csv
│   ├── payments.csv
│   ├── products.csv
│   ├── sellers.csv
│   └── shipping.csv
├── scripts/
│   ├── schema.sql
│   ├── data_cleaning.sql
│   ├── marketplace_analysis.sql
│   └── inventory_trigger.sql
└── docs/
    └── ERD.png
```

## How to Use the Project

1. Create a SQL Server database.
2. Create the tables using `scripts/schema.sql`.
3. Import the CSV files from `data/` using SQL Server Import/Export Wizard, `BULK INSERT`, or an equivalent loading process.
4. Run `scripts/data_cleaning.sql` to normalize status fields and validate relationships.
5. Run `scripts/marketplace_analysis.sql` to reproduce the business findings.
6. Run `scripts/inventory_trigger.sql` separately after reviewing the stock validation and transaction logic.

## Project Outcome

This project demonstrates an end-to-end SQL workflow: validating a relational dataset, defining trustworthy business metrics, testing operational hypotheses, applying advanced analytical techniques, and translating findings into practical decisions. Its central conclusion is that marketplace health should be evaluated not only through top-line value, but also through concentration, customer repeat behavior, fulfillment reliability, and inventory exposure.

**Author:** Sanchit Duggal    
**Repository:** https://github.com/SanchitDuggal2006/E-Commerce-Marketplace-Strategic-Audit
