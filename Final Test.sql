-- Thêm dòng product_category_name bị thiếu cho bảng product_category_name_translation
insert INTO product_category_name_translation 
SELECT DISTINCT P.product_category_name, P.product_category_name as product_category_name_english FROM products P left JOIN product_category_name_translation PC ON P.product_category_name = PC.product_category_name
WHERE P.product_category_name is Not null and PC.product_category_name is null

SELECT * FROM product_category_name_translation

-- 1. Nhóm khách hàng Best Customers có đặc điểm như thế nào? Số lượng?

WITH 
seagment_tbl AS
(
    SELECT 
        C.customer_unique_id, 
        MIN(DATEDIFF(DAY, O.order_purchase_timestamp,GETDATE())) Recency,
        COUNT(O.order_id) Frequency,
        SUM(OP.payment_value) Monetary
    FROM orders O JOIN order_payments OP ON O.order_id = OP.order_id
                JOIN customers C ON O.customer_id = C.customer_id
    where order_status = 'delivered'
    GROUP BY C.customer_unique_id
), 
RFM_tbl AS
(
    SELECT 
        customer_unique_id,
        CONCAT(NTILE(5) OVER(ORDER BY Recency DESC) - 1,NTILE(5) OVER(ORDER BY Frequency ASC) - 1,NTILE(5) OVER(ORDER BY Monetary ASC) - 1) RFM_Score
    FROM seagment_tbl
)
SELECT
    customer_unique_id,
    CASE 
    WHEN RFM_Score in ('444','443','433','434','343','344','334') THEN 'VIP Champions'
    WHEN RFM_Score in ('432','333','324','244','243','234','233','224') THEN 'Loyal'
    WHEN RFM_Score in ('442','440','441','430','431','422','421','420','341','340','331','330','320','342','322','321','312','242','241','240','231','230','222','212') THEN 'Potential Loyalist'
    WHEN RFM_Score in ('414','413','412','411','410','404','403','402','314','313','302','303','304','204','203','202') THEN 'Promising'
    WHEN RFM_Score in ('401','400','311','310','301','300','200') THEN 'New Customers'
    WHEN RFM_Score in ('424','423','332','323','232','223','214','213') THEN 'Need Attention'
    WHEN RFM_Score in ('220','210','201','110','102','120','130','140') THEN 'About To Sleep'
    WHEN RFM_Score in ('144','143','134','133','142','141','132','131','124','123','114','113','042','041','034','032','031','024','023','022','014','013') THEN 'At Risk'
    WHEN RFM_Score in ('044','043','033','103','104','004','003','002') THEN 'Cannot Lose Them'
    WHEN RFM_Score in ('221','211','122','121','112','111','021','012','011','101','100') THEN 'Hibernating customers'
    WHEN RFM_Score in ('000','001','010','020','030','040') THEN 'Lost customers' END seagment
INTO #Final_tbl_1
FROM RFM_tbl

    -- Nhóm khách hàng Best Customers có đặc điểm như thế nào?
SELECT * FROM #Final_tbl_1 F JOIN customers C ON F.customer_unique_id = C.customer_unique_id
WHERE seagment = 'VIP Champions'
    -- Số lượng
SELECT COUNT(*) FROM #Final_tbl_1 WHERE seagment = 'VIP Champions'

-- 2. Đâu là các khách hàng rời bỏ? Số lượng?
-- Khách hàng rời bỏ là các khách hàng thuộc nhóm At Risk, Cannot Lose Them, Hibernating customers, Lost customers đã rất lâu không mua hàng:

SELECT * FROM #final_tbl_1
WHERE seagment in ('At Risk', 'Cannot Lose Them', 'Hibernating customers', 'Lost customers')

-- Số lượng:

SELECT count(*) FROM #final_tbl_1
WHERE seagment in ('At Risk', 'Cannot Lose Them', 'Hibernating customers', 'Lost customers')

--3. Nhóm khách hàng có khả năng Churned có đặc điểm như thế nào ?

SELECT
    FN.*,
    C.customer_city,
    OP.payment_type,
    OP.payment_installments,
    OP.payment_value,
    ORV.review_score
FROM #final_tbl_1 FN 
    JOIN customers C ON FN.customer_unique_id = C.customer_unique_id
    JOIN orders O ON C.customer_id = O.customer_id
    JOIN order_payments OP ON O.order_id = OP.order_id
    JOIN order_reviews ORV ON O.order_id = ORV.order_id
WHERE seagment in ('At Risk', 'Cannot Lose Them', 'Hibernating customers', 'Lost customers')