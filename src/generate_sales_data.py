import math
import numpy as np
from datetime import date, timedelta
import random

from db import db



np.random.seed(134289)
sample_size_prop = 0.8
min_release_date = date(2015,1,1)
max_release_date = date(2025,1,1)


seasonality = [
    1,  # January
    1,  # February
    1,  # March
    1,  # April
    1,  # May
    1,  # June
    1,  # July
    1,  # August
    1,  # September
    1,  # October
    1,  # November
    1]  # December



# attaching predictor columns to our database tables
db.runQuery("ALTER TABLE sc.locations ADD COLUMN loc_multiplier FLOAT DEFAULT 0")
db.runQuery("ALTER TABLE sc.products ADD COLUMN adv_budget FLOAT; DEFAULT 0")
db.runQuery("ALTER TABLE sc.products ADD COLUMN release_date DATE DEFAULT NULL")
db.runQuery("ALTER TABLE sc.products ADD COLUMN rating INT(11) DEFAULT 0")



## ## ## ## ## ##  ## ## ##  ## ## ## ## ## ## ## ##
# GENERATE LOC_MULTIPLIER FOR LOCATIONS
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
db.runQuery("UPDATE sc.locations SET loc_multiplier = RAND() + 0.5 WHERE location_type = 'S'")


## ## ## ## ## ##  ## ## ##  ## ## ## ## ## ## ## ##
# GENERATE ADV_BUDGET AND RELEASE DATE FOR PRODUCTS
## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##

# get randomly sorted list of products
products  = db.fetchAll("SELECT * FROM sc.products ORDER BY RAND()")

# Pre-allocate array to hold product adv_budgets
# release_date, ad budget, rating, product_id
product_predictors = [(date.today(), 1e5,  5, 12345)]*len(products)

#split the products into new_releases and old
n_old_release = math.ceil(sample_size_prop*len(products))
n_new_release = len(products) - n_old_release
#Remember, products were returned from DB using ORDER BY RAND()
# set predictors for all old products

for i in range(0,len(products)):
    # Generate adv_budget
    adv_budget = round(np.random.normal(loc=1e5, scale=1e3))
    #old releases
    if i < n_old_release:
        max_days_since_release = (date.today() - min_release_date).days
        days_since_release = round(random.uniform(0, max_days_since_release))
        release_date = date.today() - timedelta(days=days_since_release)
        rating = np.random.binomial(5, 0.8, 1)[0]
    # new releases
    else:
        max_days_until_release = (max_release_date - date.today()).days
        days_until_release = round(random.uniform(0, max_days_until_release))
        release_date = date.today() + timedelta(days=days_until_release)
        rating = 0

    rating = str(rating)
    release_date = str(release_date)

    product_predictors[i] = [release_date, adv_budget, rating, products[i]['product_id']]


#Send update list to database
stmt = "UPDATE sc.products SET release_date = %s, adv_budget = %s, rating = %s WHERE product_id = %s"
# print(stmt % (product_predictors[1][0], product_predictors[1][1], product_predictors[1][2], product_predictors[1][3]))
db.executemany(stmt, product_predictors)






## ## ## ## ## ##  ## ## ##  ## ## ##
# GENERATE SALES HISTORIES
## ## ## ## ## ## ## ## ## ## ## ## ##

# Pull all prod/locations which will need a sales history
prod_loc = db.fetchAll(
    '''
    SELECT pl.id, 
           p.product_id, 
           l.location_id, 
           l.loc_multiplier, 
           p.adv_budget, 
           p.release_date,
           p.rating 
      FROM sc.product_location pl, 
           sc.products p, 
           sc.locations l 
     WHERE p.release_date < CURDATE() 
       AND p.product_id   = pl.product_id
       AND l.location_id  = pl.location_id
     ORDER BY RAND()
     '''
)


pl_sales = []

## NOTE - alot of this could be vectorized
for pl in prod_loc:
    #Linear Coefficients
    B0 = 1
    B1 = 1

    # Calculating sales on release day for location

    start_date = pl['release_date']
    end_date = date.today()

    # Iterating over all dates which product has been selling at this location
    current_date = start_date

    while current_date <= end_date:
        # lookup seasonality of date
        season_multiplier = seasonality[current_date.month-1]
        # lookup days since release
        x = end_date - current_date
        x = x.days
        # linear coefficients for day0_sales ~ adv_budget + loc_multiplier + season_multiplier + rating
        B0 = 1
        B1 = 1

        # std_day0_sales is the first parameterization for the exponential curve
        # std_day0_sales = (B0 + B1*budget)*loc_multiplier =>
        std_day0_sales = B0 * pl['loc_multiplier'] + B1 * pl['adv_budget'] * pl['loc_multiplier']
        # sales curve is exponential, parameterized by height(std_day0_sales) and decay exp(-1/(6*pl.rating)
        current_day_sales = std_day0_sales * np.exp(-1 / (6 * pl['rating']))
        # Measured values always have some noise
        current_day_sales = np.random.normal(current_day_sales, 0.2 * current_day_sales)
        current_day_sales = round(current_day_sales)
        # save the result
        pl_sales.append([pl['product_id'], pl['location_id'], current_date, current_day_sales])




        # Advancing current date by one day
        current_date = current_date + timedelta(days=1)

stmt = "INSERT INTO sc.sales(product_id, location_id, sale_date, sale_amt) VALUES(%s,%s,%s,%s)"
db.executemany(stmt, pl_sales)

