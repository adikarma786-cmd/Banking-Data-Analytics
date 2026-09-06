
I. Initial Exploratory Analysis
Objective: Understand the dataset's structure and key characteristics to establish a foundation for deeper analysis.

I.A. Data types for columns in the 'customers' table
•	Hint: Use the information_schema.columns view to query the data types by filtering on the 'customers' table and 'Citibank' schema.
Query-   

SELECT
    column_name,
    data_type
FROM `scaler-dsml-sql-498010.citibank.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name = 'customers';


  I.B. Identify the date range covered in the Citibank customer and transaction data by finding:

Query- SELECT min(created_at) as min_creation_date,
max(created_at) as max_creation_date

FROM `scaler-dsml-sql-498010.citibank.customers` ; 
 

SELECT min(transaction_date) as min_transaction_date,
max(transaction_date) as max_transaction_date

FROM `scaler-dsml-sql-498010.citibank.transactions` ; 


  I.C. List the name of each branch, the type of account, and the status of the account, along with the total number of accounts for each combination, and show the results sorted by branch name and then by the number of accounts from highest to lowest.

Query- 
 select b.branch_name, 
a.account_type,
a.status, 
sum(a.account_id) total_number_of_accounts

from citibank.branches b
join citibank.accounts a 
on a.branch_id=b.branch_id 
group by b.branch_name, 
a.account_type,
a.status

order by b.branch_name, total_number_of_accounts desc

