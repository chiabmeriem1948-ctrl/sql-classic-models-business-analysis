/* Analyse générale des Tables */
SHOW TABLES;

/* Table Client */
DESCRIBE classicmodels.customers;
/* Nombre Total des clients : 122 */
SELECT COUNT(*) AS total_customers
FROM classicmodels.customers;

/*Répartition des clients par pays */ 
SELECT country, COUNT(*) AS total_clients
FROM classicmodels.customers
GROUP BY country
ORDER BY total_clients DESC;

/* Les Top 5 des clients par chiffre d'affaire */
SELECT 
    customers.customerName, 
    orders.customerNumber, 
    COUNT(orders.orderNumber) AS total_orders, 
    SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS total_revenue, 
    (SUM(orderdetails.quantityOrdered * orderdetails.priceEach) / 
     (SELECT SUM(orderdetails.quantityOrdered * orderdetails.priceEach) FROM classicmodels.orderdetails) * 100) AS revenue_percentage
FROM 
    classicmodels.orders
JOIN 
    classicmodels.customers ON orders.customerNumber = customers.customerNumber
JOIN 
    classicmodels.orderdetails ON orders.orderNumber = orderdetails.orderNumber
GROUP BY 
    orders.customerNumber, customers.customerName
ORDER BY 
    total_revenue DESC
LIMIT 5;

/* top 5 des clients pour chaque année*/   
/*2003*/ 
SELECT 
    YEAR(orders.orderDate) AS year, 
    customers.customerName, 
    COUNT(orders.orderNumber) AS total_orders,
    SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS total_revenue
FROM 
    classicmodels.orders
JOIN 
    classicmodels.customers ON orders.customerNumber = customers.customerNumber
JOIN 
    classicmodels.orderdetails ON orders.orderNumber = orderdetails.orderNumber
WHERE 
    YEAR(orders.orderDate) = 2003
GROUP BY 
    customers.customerName, year
ORDER BY 
    total_revenue DESC
LIMIT 5;

/* 2004*/ 
SELECT 
    YEAR(orders.orderDate) AS year, 
    customers.customerName, 
    COUNT(orders.orderNumber) AS total_orders,
    SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS total_revenue
FROM 
    classicmodels.orders
JOIN 
    classicmodels.customers ON orders.customerNumber = customers.customerNumber
JOIN 
    classicmodels.orderdetails ON orders.orderNumber = orderdetails.orderNumber
WHERE 
    YEAR(orders.orderDate) = 2004
GROUP BY 
    customers.customerName, year
ORDER BY 
    total_revenue DESC
LIMIT 5;

/* moitié 2005 */ 
SELECT 
    YEAR(orders.orderDate) AS year, 
    customers.customerName, 
    COUNT(orders.orderNumber) AS total_orders,
    SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS total_revenue
FROM 
    classicmodels.orders
JOIN 
    classicmodels.customers ON orders.customerNumber = customers.customerNumber
JOIN 
    classicmodels.orderdetails ON orders.orderNumber = orderdetails.orderNumber
WHERE 
    YEAR(orders.orderDate) = 2005
GROUP BY 
    customers.customerName, year
ORDER BY 
    total_revenue DESC
LIMIT 5;

/*Clients inactifs */ 
/* nombre de Client sans commande  */ 
SELECT 
    COUNT(customers.customerNumber) AS total_null_clients
FROM 
    classicmodels.customers
LEFT JOIN 
    classicmodels.orders ON customers.customerNumber = orders.customerNumber
WHERE 
    orders.orderNumber IS NULL;

/* nombre de client sans commande par office */
SELECT 
    IFNULL(offices.city, 'Unassigned Office') AS office_city, 
    IFNULL(offices.country, 'Unassigned Country') AS office_country, 
    COUNT(customers.customerNumber) AS total_null_clients
FROM 
    classicmodels.offices
LEFT JOIN 
    classicmodels.employees ON offices.officeCode = employees.officeCode
RIGHT JOIN 
    classicmodels.customers ON employees.employeeNumber = customers.salesRepEmployeeNumber
LEFT JOIN 
    classicmodels.orders ON customers.customerNumber = orders.customerNumber
WHERE 
    orders.orderNumber IS NULL
GROUP BY 
    offices.city, offices.country
ORDER BY 
    total_null_clients DESC;

/* nombre de client sans commande par pays*/ 
SELECT 
    customers.country AS customer_country, 
    COUNT(customers.customerNumber) AS total_clients
FROM 
    classicmodels.customers
LEFT JOIN 
    classicmodels.employees ON customers.salesRepEmployeeNumber = employees.employeeNumber
WHERE 
    employees.employeeNumber IS NULL
GROUP BY 
    customers.country
ORDER BY 
    total_clients DESC;

/* Nouveaux clients */
SELECT 
    YEAR(first_order) AS year, 
    COUNT(customerNumber) AS new_customers
FROM (
    SELECT 
        customers.customerNumber, 
        MIN(orders.orderDate) AS first_order
    FROM classicmodels.customers
    JOIN classicmodels.orders 
        ON customers.customerNumber = orders.customerNumber
    GROUP BY customers.customerNumber
) AS customer_first_order
GROUP BY YEAR(first_order)
ORDER BY year;
    
/* Segmentation des clients */ 
WITH customer_revenue AS (
    SELECT 
        customers.customerNumber, 
        customers.customerName, 
        SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS total_revenue
    FROM 
        classicmodels.customers
    JOIN 
        classicmodels.orders ON customers.customerNumber = orders.customerNumber
    JOIN 
        classicmodels.orderdetails ON orders.orderNumber = orderdetails.orderNumber
    GROUP BY 
        customers.customerNumber, customers.customerName
),
revenue_ranks AS (
    SELECT 
        customerNumber, 
        customerName, 
        total_revenue,
        NTILE(100) OVER (ORDER BY total_revenue DESC) AS revenue_percentile
    FROM 
        customer_revenue
)
SELECT 
    customerName, 
    total_revenue,
    CASE 
        WHEN revenue_percentile <= 10 THEN 'VIP'
        WHEN revenue_percentile > 10 AND revenue_percentile <= 60 THEN 'Intermédiaire'
        ELSE 'Faible'
    END AS customer_segment
FROM 
    revenue_ranks
ORDER BY 
    customer_segment, total_revenue DESC;

/* comparaison entre différents ségments */
WITH customer_revenue AS (
    SELECT 
        customers.customerNumber, 
        customers.customerName, 
        SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS total_revenue
    FROM 
        classicmodels.customers
    JOIN 
        classicmodels.orders ON customers.customerNumber = orders.customerNumber
    JOIN 
        classicmodels.orderdetails ON orders.orderNumber = orderdetails.orderNumber
    GROUP BY 
        customers.customerNumber, customers.customerName
),
revenue_ranks AS (
    SELECT 
        customerNumber, 
        customerName, 
        total_revenue,
        NTILE(100) OVER (ORDER BY total_revenue DESC) AS revenue_percentile
    FROM 
        customer_revenue
),
segmented_customers AS (
    SELECT 
        customerName, 
        total_revenue,
        CASE 
            WHEN revenue_percentile <= 10 THEN 'VIP'
            WHEN revenue_percentile > 10 AND revenue_percentile <= 60 THEN 'Intermédiaire'
            ELSE 'Faible'
        END AS customer_segment
    FROM 
        revenue_ranks
)
SELECT 
    customer_segment,
    COUNT(customerName) AS total_clients,
    SUM(total_revenue) AS segment_total_revenue,
    (SUM(total_revenue) / (SELECT SUM(total_revenue) FROM customer_revenue) * 100) AS percentage_of_global_revenue
FROM 
    segmented_customers
GROUP BY 
    customer_segment
ORDER BY 
    segment_total_revenue DESC;
    
    
/* Analyse Ressources humaines: Table Employees & Offices */ 
DESCRIBE classicmodels.employees;
DESCRIBE classicmodels.offices;
/* Nombre total des employées =23 */
SELECT COUNT(*) AS total_employees
FROM classicmodels.employees;

/* Répartition par poste */ 
SELECT jobTitle, COUNT(*) AS total_employees
FROM classicmodels.employees
GROUP BY jobTitle
ORDER BY total_employees DESC;

/* Revenu par pays, nombre de clients et d'employés */
SELECT 
    classicmodels.offices.country AS country,
    COUNT(DISTINCT classicmodels.offices.officeCode) AS total_offices,
    COUNT(DISTINCT classicmodels.employees.employeeNumber) AS total_employees,
    COUNT(DISTINCT classicmodels.customers.customerNumber) AS total_customers,
    SUM(classicmodels.orderdetails.quantityOrdered * classicmodels.orderdetails.priceEach) AS total_revenue
FROM 
    classicmodels.offices
LEFT JOIN classicmodels.employees 
    ON classicmodels.offices.officeCode = classicmodels.employees.officeCode
LEFT JOIN classicmodels.customers 
    ON classicmodels.employees.employeeNumber = classicmodels.customers.salesRepEmployeeNumber
LEFT JOIN classicmodels.orders 
    ON classicmodels.customers.customerNumber = classicmodels.orders.customerNumber
LEFT JOIN classicmodels.orderdetails 
    ON classicmodels.orders.orderNumber = classicmodels.orderdetails.orderNumber
GROUP BY 
    classicmodels.offices.country
ORDER BY 
    total_revenue DESC;
    
/* nombre de client pour chaque commercial */
SELECT 
    employees.employeeNumber,
    employees.lastName,
    employees.firstName,
    employees.jobTitle,
    offices.city AS office_city,
    offices.country AS office_country,
    COUNT(customers.customerNumber) AS total_clients
FROM 
    classicmodels.employees
LEFT JOIN 
    classicmodels.customers ON employees.employeeNumber = customers.salesRepEmployeeNumber
LEFT JOIN 
    classicmodels.offices ON employees.officeCode = offices.officeCode
WHERE 
    employees.jobTitle = 'Sales Rep'
GROUP BY 
    employees.employeeNumber, employees.lastName, employees.firstName, employees.jobTitle, offices.city, offices.country
ORDER BY 
    total_clients DESC;

/* les commeciaux sans clients */
SELECT 
    employees.employeeNumber,
    employees.lastName,
    employees.firstName,
    employees.jobTitle,
    offices.city AS office_city,
    offices.country AS office_country
FROM 
    classicmodels.employees
LEFT JOIN 
    classicmodels.customers ON employees.employeeNumber = customers.salesRepEmployeeNumber
LEFT JOIN 
    classicmodels.offices ON employees.officeCode = offices.officeCode
WHERE 
    employees.jobTitle = 'Sales Rep'
    AND customers.customerNumber IS NULL  -- Aucun client attribué
ORDER BY 
    offices.city, employees.lastName;


/* Table orderdetails & order */ 
DESCRIBE classicmodels.orderdetails;
DESCRIBE classicmodels.orders;

/* Nombre total des commandes */ 
SELECT 
    COUNT(orderNumber) AS total_orders
FROM 
    classicmodels.orders;

/* Annuel */ 
SELECT 
    YEAR(orders.orderDate) AS year, 
    COUNT(orders.orderNumber) AS total_orders
FROM 
    classicmodels.orders
GROUP BY 
    YEAR(orders.orderDate)
ORDER BY 
    year;

/* semestriel */
SELECT 
    YEAR(orders.orderDate) AS year, 
    CASE 
        WHEN MONTH(orders.orderDate) BETWEEN 1 AND 6 THEN '1st Semester'
        WHEN MONTH(orders.orderDate) BETWEEN 7 AND 12 THEN '2nd Semester'
    END AS semester,
    COUNT(orders.orderNumber) AS total_orders
FROM 
    classicmodels.orders
GROUP BY 
    YEAR(orders.orderDate), semester
ORDER BY 
    year, semester;
    
/* mensuel */ 
SELECT 
    YEAR(orders.orderDate) AS year, 
    MONTH(orders.orderDate) AS month, 
    COUNT(orders.orderNumber) AS total_orders
FROM 
    classicmodels.orders
GROUP BY 
    YEAR(orders.orderDate), MONTH(orders.orderDate)
ORDER BY 
    year, month;

/* Status des commandes avec CA */
SELECT 
    orders.status, 
    COUNT(DISTINCT orders.orderNumber) AS total_orders, 
    SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS total_revenue,
    (COUNT(DISTINCT orders.orderNumber) / 
     (SELECT COUNT(DISTINCT orderNumber) FROM classicmodels.orders) * 100) AS percentage_of_orders
FROM 
    classicmodels.orders
JOIN 
    classicmodels.orderdetails ON orders.orderNumber = orderdetails.orderNumber
GROUP BY 
    orders.status
ORDER BY 
    total_orders DESC;

/* identifier les retards */
SELECT COUNT(orders.orderNumber) AS total_late_orders
FROM classicmodels.orders
WHERE orders.shippedDate > orders.requiredDate;

/* Table Payments */ 
DESCRIBE classicmodels.payments;

SELECT 
    year_table.year, 
    year_table.total_revenue,
    payments_table.total_payments,
    year_table.total_revenue - payments_table.total_payments AS difference
FROM
    (SELECT 
        YEAR(orders.orderDate) AS year,
        SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS total_revenue
     FROM 
        classicmodels.orders
     JOIN 
        classicmodels.orderdetails ON orders.orderNumber = orderdetails.orderNumber
     GROUP BY 
        YEAR(orders.orderDate)) AS year_table
LEFT JOIN
    (SELECT 
        YEAR(paymentDate) AS year,
        SUM(amount) AS total_payments
     FROM 
        classicmodels.payments
     GROUP BY 
        YEAR(paymentDate)) AS payments_table
ON 
    year_table.year = payments_table.year
ORDER BY 
    year_table.year;

/* Gestion du Stock */
DESCRIBE classicmodels.productlines;
DESCRIBE classicmodels.products;

/* nombre total de produit =110 */ 
SELECT 
    COUNT(*) AS total_products
FROM 
    classicmodels.products;
    
/* Total produit vendus=109 */
SELECT 
    COUNT(DISTINCT orderdetails.productCode) AS total_sold_products
FROM 
    classicmodels.orderdetails;

/* Total quantité en Stock */    
SELECT SUM(quantityInStock) AS total_stock
FROM classicmodels.products;

/* Produit non vendus */
SELECT 
    products.productCode, 
    products.productName, 
    products.quantityInStock AS total_stock, 
    products.buyPrice AS unit_cost, 
    (products.quantityInStock * products.buyPrice) AS total_stock_value
FROM 
    classicmodels.products
LEFT JOIN 
    classicmodels.orderdetails ON products.productCode = orderdetails.productCode
WHERE 
    orderdetails.productCode IS NULL
ORDER BY 
    products.productName;

/* quantité et valeur en stock: par produit */ 
SELECT 
    products.productCode,
    products.productName,
    products.quantityInStock AS total_quantity_in_stock,
    products.buyPrice AS unit_cost,
    (products.quantityInStock * products.buyPrice) AS total_stock_value
FROM 
    classicmodels.products
ORDER BY 
    total_stock_value DESC;
    
/* quantité et valeur en stock: par type de produit */
SELECT 
    productlines.productLine, 
    COUNT(products.productCode) AS total_products, -- Nombre total de produits par catégorie
    SUM(products.quantityInStock) AS total_quantity_in_stock, -- Quantité totale en stock
    SUM(products.quantityInStock * products.buyPrice) AS total_stock_value -- Valeur totale en stock
FROM 
    classicmodels.productlines
JOIN 
    classicmodels.products ON productlines.productLine = products.productLine
GROUP BY 
    productlines.productLine
ORDER BY 
    total_quantity_in_stock DESC;
    

/* Produits en Stock non commandé */ 
  SELECT 
    products.productName, 
    products.quantityInStock AS total_stock,
    COALESCE(SUM(orderdetails.quantityOrdered), 0) AS reserved_stock,
    (products.quantityInStock - COALESCE(SUM(orderdetails.quantityOrdered), 0)) AS available_stock,
    (products.quantityInStock - COALESCE(SUM(orderdetails.quantityOrdered), 0)) * products.buyPrice AS stock_value_unordered
FROM 
    classicmodels.products
LEFT JOIN 
    classicmodels.orderdetails ON products.productCode = orderdetails.productCode
LEFT JOIN 
    classicmodels.orders ON orderdetails.orderNumber = orders.orderNumber
WHERE 
    orders.status NOT IN ('Shipped', 'Cancelled') OR orders.status IS NULL -- Exclure les commandes expédiées ou annulées
GROUP BY 
    products.productCode, products.productName, products.quantityInStock, products.buyPrice
ORDER BY 
    stock_value_unordered DESC;
    
/* stock non commandé par catégorie*/ 

DROP TABLE IF EXISTS classicmodels.product_stock_summary;

-- Créer une nouvelle table pour stocker le résumé du stock par catégorie de produit
CREATE TABLE classicmodels.product_stock_summary (
    category VARCHAR(255) PRIMARY KEY,
    total_stock INT,
    reserved_stock INT,
    available_stock INT,
    stock_value_unordered DECIMAL(15,2)
);

-- Insérer les données agrégées par catégorie de produit
INSERT INTO classicmodels.product_stock_summary (category, total_stock, reserved_stock, available_stock, stock_value_unordered)
SELECT 
    productlines.productLine AS category,
    SUM(products.quantityInStock) AS total_stock,
    COALESCE(SUM(orderdetails.quantityOrdered), 0) AS reserved_stock,
    (SUM(products.quantityInStock) - COALESCE(SUM(orderdetails.quantityOrdered), 0)) AS available_stock,
    (SUM(products.quantityInStock) - COALESCE(SUM(orderdetails.quantityOrdered), 0)) * AVG(products.buyPrice) AS stock_value_unordered
FROM 
    classicmodels.productlines
JOIN 
    classicmodels.products ON productlines.productLine = products.productLine
LEFT JOIN 
    classicmodels.orderdetails ON products.productCode = orderdetails.productCode
LEFT JOIN 
    classicmodels.orders ON orderdetails.orderNumber = orders.orderNumber
WHERE 
    orders.status NOT IN ('Shipped', 'Cancelled') OR orders.status IS NULL -- Exclure les commandes expédiées ou annulées
GROUP BY 
    productlines.productLine
ORDER BY 
    stock_value_unordered DESC;

/* produits plus coûteux */ 
SELECT 
    productlines.productLine AS category, 
    products.productCode, 
    products.productName, 
    products.buyPrice, 
    products.quantityInStock
FROM 
    classicmodels.products
JOIN 
    classicmodels.productlines ON products.productLine = productlines.productLine
ORDER BY 
    products.buyPrice DESC
LIMIT 5;


/* Top 5 des produits */ 
SELECT 
    products.productName, 
    SUM(orderdetails.quantityOrdered) AS total_quantity, 
    SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS total_revenue, 
    (SUM(orderdetails.quantityOrdered * orderdetails.priceEach) / 
     (SELECT SUM(quantityOrdered * priceEach) 
      FROM classicmodels.orderdetails) * 100) AS revenue_percentage
FROM 
    classicmodels.orderdetails
JOIN 
    classicmodels.products ON orderdetails.productCode = products.productCode
JOIN 
    classicmodels.orders ON orderdetails.orderNumber = orders.orderNumber
GROUP BY 
    products.productName
ORDER BY 
    total_revenue DESC
LIMIT 5;

/* TOP 5 produit 2003 */
SELECT 
    YEAR(orders.orderDate) AS year, 
    products.productName, 
    SUM(orderdetails.quantityOrdered) AS total_quantity, 
    SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS total_revenue, 
    (SUM(orderdetails.quantityOrdered * orderdetails.priceEach) / 
     (SELECT SUM(quantityOrdered * priceEach) 
      FROM classicmodels.orderdetails 
      JOIN classicmodels.orders ON orderdetails.orderNumber = orders.orderNumber
      WHERE YEAR(orders.orderDate) = 2003) * 100) AS revenue_percentage
FROM 
    classicmodels.orderdetails
JOIN 
    classicmodels.products ON orderdetails.productCode = products.productCode
JOIN 
    classicmodels.orders ON orderdetails.orderNumber = orders.orderNumber
WHERE 
    YEAR(orders.orderDate) = 2003
GROUP BY 
    year, products.productName
ORDER BY 
    total_revenue DESC
LIMIT 5;

/* TOP 5 produit 2004*/
SELECT 
    YEAR(orders.orderDate) AS year, 
    products.productName, 
    SUM(orderdetails.quantityOrdered) AS total_quantity, 
    SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS total_revenue, 
    (SUM(orderdetails.quantityOrdered * orderdetails.priceEach) / 
     (SELECT SUM(quantityOrdered * priceEach) 
      FROM classicmodels.orderdetails 
      JOIN classicmodels.orders ON orderdetails.orderNumber = orders.orderNumber
      WHERE YEAR(orders.orderDate) = 2004) * 100) AS revenue_percentage
FROM 
    classicmodels.orderdetails
JOIN 
    classicmodels.products ON orderdetails.productCode = products.productCode
JOIN 
    classicmodels.orders ON orderdetails.orderNumber = orders.orderNumber
WHERE 
    YEAR(orders.orderDate) = 2004
GROUP BY 
    year, products.productName
ORDER BY 
    total_revenue DESC
LIMIT 5;

/* TOP 5 produit 2005 */ 
SELECT 
    YEAR(orders.orderDate) AS year, 
    products.productName, 
    SUM(orderdetails.quantityOrdered) AS total_quantity, 
    SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS total_revenue, 
    (SUM(orderdetails.quantityOrdered * orderdetails.priceEach) / 
     (SELECT SUM(quantityOrdered * priceEach) 
      FROM classicmodels.orderdetails 
      JOIN classicmodels.orders ON orderdetails.orderNumber = orders.orderNumber
      WHERE YEAR(orders.orderDate) = 2005) * 100) AS revenue_percentage
FROM 
    classicmodels.orderdetails
JOIN 
    classicmodels.products ON orderdetails.productCode = products.productCode
JOIN 
    classicmodels.orders ON orderdetails.orderNumber = orders.orderNumber
WHERE 
    YEAR(orders.orderDate) = 2005
GROUP BY 
    year, products.productName
ORDER BY 
    total_revenue DESC
LIMIT 5;

/* Vente par catégorie */
SELECT 
    productlines.productLine AS category,
    SUM(orderdetails.quantityOrdered) AS total_quantity_sold, -- Quantité totale vendue
    SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS total_revenue -- Chiffre d'affaires total
FROM 
    classicmodels.productlines
JOIN 
    classicmodels.products ON productlines.productLine = products.productLine
JOIN 
    classicmodels.orderdetails ON products.productCode = orderdetails.productCode
GROUP BY 
    productlines.productLine
ORDER BY 
    total_revenue DESC;

/* Gestion de rupture de stock */
SELECT 
    productCode, 
    productName, 
    quantityInStock AS stock_remaining
FROM 
    classicmodels.products
ORDER BY 
    quantityInStock ASC
LIMIT 5;

/* analyse 5 produits*/ 
SELECT 
    products.productCode,
    products.productName,
    SUM(orderdetails.quantityOrdered) AS total_quantity_sold,
    SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS total_revenue
FROM 
    classicmodels.products
JOIN 
    classicmodels.orderdetails ON products.productCode = orderdetails.productCode
WHERE 
    products.productCode IN ('S24_2000', 'S12_1099', 'S32_4289', 'S32_1374', 'S72_3212') -- Les 5 produits
GROUP BY 
    products.productCode, products.productName
ORDER BY 
    total_quantity_sold DESC;

/* Anlyse du Chiffre d'affaire */ 
/* Chiffre d'Affaire Global */
SELECT 
    SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS total_revenue
FROM 
    classicmodels.orderdetails;
    
/* Chiffre d'Affaire Annuel */
SELECT 
    YEAR(orders.orderDate) AS year, 
    SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS annual_revenue
FROM 
    classicmodels.orders
JOIN 
    classicmodels.orderdetails ON orders.orderNumber = orderdetails.orderNumber
GROUP BY 
    YEAR(orders.orderDate)
ORDER BY 
    year;
    
/* Chiffre d'Affaire Mensuel */
SELECT 
    YEAR(orders.orderDate) AS year,
    MONTH(orders.orderDate) AS month,
    SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS monthly_revenue
FROM 
    classicmodels.orders
JOIN 
    classicmodels.orderdetails ON orders.orderNumber = orderdetails.orderNumber
GROUP BY 
    YEAR(orders.orderDate), MONTH(orders.orderDate)
ORDER BY 
    year, month;
    
/* Chiffre d'Affaire Semestriel */
SELECT 
    YEAR(orders.orderDate) AS year,
    CASE 
        WHEN MONTH(orders.orderDate) BETWEEN 1 AND 6 THEN '1st Semester'
        WHEN MONTH(orders.orderDate) BETWEEN 7 AND 12 THEN '2nd Semester'
    END AS semester,
    SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS semester_revenue
FROM 
    classicmodels.orders
JOIN 
    classicmodels.orderdetails ON orders.orderNumber = orderdetails.orderNumber
GROUP BY 
    YEAR(orders.orderDate), semester
ORDER BY 
    year, semester;
 
 
 /* taux de croissance CA 2003 2004 */
WITH revenue_by_year AS (
    SELECT 
        YEAR(orders.orderDate) AS year,
        SUM(orderdetails.quantityOrdered * orderdetails.priceEach) AS total_revenue
    FROM 
        classicmodels.orders
    JOIN 
        classicmodels.orderdetails ON orders.orderNumber = orderdetails.orderNumber
    WHERE 
        YEAR(orders.orderDate) IN (2003, 2004)
    GROUP BY 
        YEAR(orders.orderDate)
),
cagr_calculation AS (
    SELECT 
        (SELECT total_revenue FROM revenue_by_year WHERE year = 2004) AS revenue_2004,
        (SELECT total_revenue FROM revenue_by_year WHERE year = 2003) AS revenue_2003
)
SELECT 
    revenue_2003,
    revenue_2004,
    POWER((revenue_2004 / revenue_2003), (1.0 / 1)) - 1 AS taux_de_croissance -- 1 correspond à une différence d'années (2004 - 2003)
FROM 
    cagr_calculation;
