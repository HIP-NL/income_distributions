# Income distributions for the Netherlands, 1860-1920

This repository contains the data processing work to turn the muncipal tax records into consistent income distributions.

It contains the following scripts.

- estimate_incomes_63.R: cleans tax records and estimates harmonised income for each record. Depends on:
    - moves.R: removes duplicate observations for households that moved
    - households.R: aggregate to consistent households
    - munic_income_fixes.R: fix various mistakes in tax records
- imputations_63.R: imputes missing observations to create full distributions
- functions.R: helper functions.

The following dataset are included.

- alpha_year_mun_id.txt: list of municipalities where households are ordered alphabetically in the source and cannot readily be aggretated to 
- priceindex.csv: price index from IISH-HPW. Todo: check replacing with CBS series https://opendata.cbs.nl/#/CBS/nl/dataset/71905ned/table?ts=1775255897695
- refpop_pred_63.csv: reference population for each municipality in the data


