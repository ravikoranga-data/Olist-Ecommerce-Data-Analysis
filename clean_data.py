import pandas as pd
from sqlalchemy import create_engine

# load raw csv files
orders = pd.read_csv('data/olist_orders_dataset.csv')
items = pd.read_csv('data/olist_order_items_dataset.csv')
products = pd.read_csv('data/olist_products_dataset.csv')
cat_trans = pd.read_csv('data/product_category_name_translation.csv')
customers = pd.read_csv('data/olist_customers_dataset.csv')
payments = pd.read_csv('data/olist_order_payments_dataset.csv')
reviews = pd.read_csv('data/olist_order_reviews_dataset.csv')

# convert order date columns to datetime
order_dates = [
    'order_purchase_timestamp',
    'order_approved_at',
    'order_delivered_carrier_date',
    'order_delivered_customer_date',
    'order_estimated_delivery_date'
]
for c in order_dates:
    orders[c] = pd.to_datetime(orders[c], errors='coerce')

orders = orders.drop_duplicates()

# merge english category names and fill missing values
products = products.merge(cat_trans, on='product_category_name', how='left')
products['product_category_name_english'] = products['product_category_name_english'].fillna('unknown')

for col in ['product_weight_g', 'product_length_cm', 'product_height_cm', 'product_width_cm']:
    products[col] = products[col].fillna(products[col].median())

products = products.drop_duplicates()

# clean city and state formatting
customers['customer_city'] = customers['customer_city'].str.strip().str.title()
customers['customer_state'] = customers['customer_state'].str.strip().str.upper()
customers = customers.drop_duplicates()

# remove invalid price/payment records
items['shipping_limit_date'] = pd.to_datetime(items['shipping_limit_date'], errors='coerce')
items = items[items['price'] > 0].drop_duplicates()

payments = payments[payments['payment_value'] > 0].drop_duplicates()

# handle missing review text and duplicates
reviews['review_creation_date'] = pd.to_datetime(reviews['review_creation_date'], errors='coerce')
reviews['review_comment_title'] = reviews['review_comment_title'].fillna('No Title')
reviews['review_comment_message'] = reviews['review_comment_message'].fillna('No Comment')
reviews = reviews.drop_duplicates(subset=['review_id'])

# load cleaned tables into postgresql
db_url = 'postgresql://postgres:1234@localhost:5432/olist_db'
engine = create_engine(db_url)

data_map = {
    'orders': orders,
    'order_items': items,
    'products': products,
    'customers': customers,
    'order_payments': payments,
    'order_reviews': reviews
}

for tbl_name, df in data_map.items():
    df.to_sql(tbl_name, engine, if_exists='replace', index=False)
    print(f"{tbl_name}: {len(df)} rows loaded")