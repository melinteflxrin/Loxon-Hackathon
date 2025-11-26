import pandas as pd
import numpy as np
from faker import Faker
import os

fake = Faker()

# Parameters
n_customers = 100
n_orders = 300
n_payments = 350

# Generate st_customers
def generate_customers(n):
    data = []
    for i in range(1, n+1):
        data.append({
            'customer_id': str(i),
            'full_name': fake.name(),
            'email': fake.email(),
            'phone': fake.phone_number(),
            'reg_date': fake.date_between(start_date='-3y', end_date='today').strftime('%Y-%m-%d')
        })
    return pd.DataFrame(data)

# Generate st_orders
def generate_orders(n, customer_ids):
    data = []
    for i in range(1, n+1):
        cust_id = np.random.choice(customer_ids)
        order_date = fake.date_between(start_date='-2y', end_date='today')
        data.append({
            'order_id': str(i),
            'customer_id': cust_id,
            'order_date': order_date.strftime('%Y-%m-%d'),
            'amount': str(np.random.randint(50, 2000)),
            'currency': 'HUF'
        })
    return pd.DataFrame(data)

# Generate st_payments
def generate_payments(n, order_ids):
    data = []
    for i in range(1, n+1):
        order_id = np.random.choice(order_ids)
        payment_date = fake.date_between(start_date='-2y', end_date='today')
        data.append({
            'payment_id': str(i),
            'order_id': order_id,
            'payment_date': payment_date.strftime('%Y-%m-%d'),
            'amount': str(np.random.randint(50, 2000)),
            'method': np.random.choice(['card', 'transfer', 'cash'])
        })
    return pd.DataFrame(data)

if __name__ == "__main__":
    customers = generate_customers(n_customers)
    orders = generate_orders(n_orders, customers['customer_id'].tolist())
    payments = generate_payments(n_payments, orders['order_id'].tolist())

    # Get the project root (one level up from src)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    data_dir = os.path.abspath(os.path.join(script_dir, '..', 'data'))
    os.makedirs(data_dir, exist_ok=True)

    customers.to_csv(os.path.join(data_dir, "mock_st_customers.csv"), index=False)
    orders.to_csv(os.path.join(data_dir, "mock_st_orders.csv"), index=False)
    payments.to_csv(os.path.join(data_dir, "mock_st_payments.csv"), index=False)

    print(f"Mock data generated and saved to {data_dir} directory.")
