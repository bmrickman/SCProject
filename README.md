Setup Guide:

1. Create folder  ~/SCProject
2. Clone the git repo: git clone https://github.com/bmrickman/SCProject ~/SCProject
3. use environment.yml to create a conda environment
    1. Letting PyCharm create you conda environment (so pycharm calls the correct python with dependencies when using IDE): https://www.jetbrains.com/help/pycharm/conda-support-creating-conda-virtual-environment.html#conda-requirements
    2. Or Create a Conda environment manually: conda env create -f environment.yml
4. Install docker desktop
5. build mounting path for docker volume
    1. mkdir -p ~/SCProject/data/mysql
6. start a mysql8 container 
    1. docker run -d -p 3306:3306 -v ~/SCProject/data/mysql:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=password mysql:8
    2. the container id will be printed to screen
    3. use docker ps -a to view the current state of all containers
    4. At any time, stop this container with docker stop ‘{container_id}’
    5. Then restart with the following: docker start ‘{container_id}’
        1. docker remembers the port mapping
        2. docker will NOT rebuild the data/mysql directory if its empty on restart.  MySQL will probably crash if mount is tampered.
    6. If you ever want to destroy your docker workspace and start over, use docker system prune.  It’ll delete everything but images.
7. Connect a Database management tool to your container
    1. I’m using DBeaver
8. Change any needed configurations in mysql_cfg.py
9. Test the python code to make sure dependencies are installed and MySQL is connecting



Additional Guides:

My Go To Conda Guide:
https://towardsdatascience.com/a-guide-to-conda-environments-bc6180fc533

Using conda with PyCharm - setting up pycharm to use conda environment with existing envinronment.yml:
https://www.jetbrains.com/help/pycharm/conda-support-creating-conda-virtual-environment.html

A guide on Docker and MySQL:
https://www.serverlab.ca/tutorials/containers/docker/how-to-run-mysql-server-8-in-a-docker-container/


Project Overview:
the goal of the project is to support the following workflow:
1. Simulate Supply Chain structure
2. Simulate historical data for said configuration
3. Infer structure of sales/production/build/etc based on historical data using ML/Stats
4. document model performance (both runtime and prediction accuracy)


Project Directory Overview:
1. db.py                       - module for connecting to database
2. mysql_cfg.py                - database connection configuration
3. tests                       - test files (currently on DB test)
4. create_supply_chain.py      - passes SQL file to MySQL for supply chain generation
5. environment.yml             - conda environment file
6. db_init_shallow_dvd_sc.sql  - Generates a 'shallow' supply chain
7.generate_sales_data_wip.py   - Work in Progress.  Used to generate historical predictor and response values.


TODO:
1. consider permissions/security issues
2. wrap python code in docker container
3. finish sales generation logic
4. build documentation on sales generation logic
