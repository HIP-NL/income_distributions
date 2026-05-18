# income estimates

rm(list = ls())

setwd("~/repos/income_distributions")

source("./src/functions.R")

tax_records_path = "~/data/hipnl-processed/data/tax_records/versions"

library("arrow")
library("data.table")
library("xgboost")

# tax = arrow::read_parquet("tax_records_2025_02_28_v5.parquet")
# sch = arrow::read_parquet("tax_schedule_2025_02_28_v5.parquet")
# met = arrow::read_parquet("metadata_wide_2025_02_28_v5.parquet")
# tax = arrow::read_parquet("tax_records_2025_04_24_v6.0.0.parquet")
# sch = arrow::read_parquet("tax_schedule_2025_04_24_v6.0.0.parquet")
# met = arrow::read_parquet("metadata_wide_2025_04_24_v6.0.0.parquet")
tax = arrow::read_parquet(file.path(tax_records_path, "tax_records_2025_05_28_v6.3.0.parquet"))
sch = arrow::read_parquet(file.path(tax_records_path, "tax_schedule_2025_05_28_v6.3.0.parquet"))
met = arrow::read_parquet(file.path(tax_records_path, "metadata_wide_2025_05_28_v6.3.0.parquet"))

data.table::setDT(tax)
data.table::setDT(sch)
data.table::setDT(met)

persvars = c("year_mun_id", "volgnummer", "firstnames", "initials", "surname", "street", 
    "house_nr_street", "wijk", "house_nr_wijk", "moved_address", "record_guid")

taxvrbs = c("income_taxable", "income_gross", "income_unspecified", "income_raad",
    "tax", "tax2", 
    # "mid",
    "class"
)
inspvrbs = c("months", "deductions", "taxrate", "mid", taxvrbs)


# row counter to keep order intact
tax[, row := .I]

# decades for aggregation
tax[, dec := round(year, -1)]

# hard name duplicates within year_mun_id (records)
tax[, dupl := duplicated(paste(firstnames, initials, surname)), by = year_mun_id]



# empty children 0 where appropriate
mun_with_children_reported = tax[, mean(!is.na(n_children)), by = year_mun_id][order(V1)][V1 > 0.25, year_mun_id]
tax[year_mun_id %in% mun_with_children_reported & is.na(n_children), n_children := 0]
tax[!year_mun_id %in% mun_with_children_reported, n_children := NA]



# -------------------------------- 
# clean and merge in tax schedules
# -------------------------------- 

# only min, no max, fix
sch[municipality == "Hulst"         & year == 1879, min := max]
sch[municipality == "Brouwershaven" & year == 1889, min := max]
sch[municipality == "Brummen"       & year == 1909, min := max]
sch[municipality == "Swalmen"       & year == 1920, min := max] # one empty
sch[municipality == "Varik"         & year == 1920, min := max]
sch[municipality == "Beesd"         & year == 1920, min := 200] # one empty, lowest bracket
sch[municipality == "Brummen"       & year == 1909, min := max]

# fix open-ended brackets by carrying forward next diff, bit conservative really
setorder(sch, year_mun_id, min)
sch[!is.na(min), open_ended_bracket := is.na(max)]
sch[!is.na(min), max := ifelse(is.na(max), min + (min - shift(min)), max), by = year_mun_id]

# mid-value to add to tax records
sch[, mid := (min + max) / 2]

# merge in schedules
nrow(tax)
tax = merge(
    tax,
    sch[!is.na(mid) & !is.na(class_nr), list(class_nr, mid, year_mun_id, open_ended_bracket)],
    by.x = c("year_mun_id", "class"),
    by.y = c("year_mun_id", "class_nr"),
    all.x = TRUE,
    all.y = FALSE)
nrow(tax)
setorder(tax, row)


# ------------------------------------------------------------------------------
# DROP SHEETS/ROWS
# ------------------------------------------------------------------------------

# highlight aanvullend, suppletoir, forenzen kohier etc.
tax[, suppletoir := grepl("anvul|[Ss]up|[Nn]av|[Oo]nin|[Ff]or|[Dd]wang|[Aa]chterst", sheet_name)]

# some suppletoir etc are complete duplicates
# 1919_Alkemade -- real dupl in aanvullingskohier
# 1917_Eindhoven -- these are extra neighbourhoods, but not consistent with previous years, so drop
dim(tax)
tax = tax[!(year_mun_id == "1917_Eindhoven" & sheet_name == "Forenzenkohier")]
dim(tax)
tax = tax[!(year_mun_id == "1917_Eindhoven" & wijk %in% c("Woensel", "Tongelre", "Stratum", "Gestel", "Strijp"))]
dim(tax)
tax = tax[!(year_mun_id == "1919_Alkemade" & sheet_name == "Aanvullingskohier ")]
dim(tax)
tax = tax[!(year_mun_id == "1909_Baexem" & sheet_name == "Baexem 1909_old")]
dim(tax)
tax = tax[year_mun_id != "1881_Harlingen"] # very low count, weird
dim(tax)
tax = tax[municipality != "het Bildt"] # until we can figure out all the issues. 1889 also seems to be borked somehow
dim(tax)
tax = tax[!(year_mun_id == "1899_Nijmegen" & (notes_entry == "Forensen")) | is.na(notes_entry)] # drop 7 forensen
dim(tax)
# one of tail nijmegen 1899 is actually forensen

# navordering in Beek, only take actual navordering
dupls_beek = tax[year_mun_id == "1920_Beek_(L.)" & duplicated(paste(firstnames, initials, surname)) & grepl("Navordering", sheet_name), paste(initials, surname, street)]
dim(tax)
tax = tax[!(year_mun_id == "1920_Beek_(L.)" & !grepl("Navordering", sheet_name) & paste(initials, surname, street) %in% dupls_beek)]
dim(tax)

# drop invalid rows
tax = tax[!(year_mun_id == "1899_Bunnik" & is.na(tax) & is.na(surname))] # volgnummer continued beyond register
dim(tax)
tax = tax[!(year_mun_id == "1872_Abcoude-Proosdij" & is.na(tax) & is.na(surname))] # all empty
dim(tax)

# share duplicates, DESERVES CLOSER LOOK
# tax[, list(share_suppl = mean(suppletoir), share_dupl = mean(dupl)), by = year_mun_id][order(share_dupl)] |> knitr::kable()
# tax[year_mun_id == "1909_Edam", .N, by = list(sheet_name, province)]
# tax[year_mun_id == "1909_Edam" & !is.na(tax), mean(dupl), by = list(sheet_name)]
# 1917_Eindhoven -- extra neighbourhoods, drop "Tweede aanvullingskohier" & check eerste en derde
# 1920_Waalwijk -- really just spread over lots of suppls
# 1909_Zaamslag -- mostly movers? Almost all are moved one address or something, drop all
# 1899_Bunnik -- basically seems to be correct? oddly
# 1872_Abcoude-Proosdij -- basically seems to be correct? oddly
# 1920_Edam seems ok maybe
# 1909_Edam seems ok maybe
# etc. rest does not seem a duplication issue, but maybe more "within
# household stuff", which we won't fix now

# needed for deduplication, moves, households etc.

tax[, fullname := safe_paste0(firstnames, initials, surname)]

# Specific data fix: triple entry, the first of which is wrong
tax = tax[!(fullname == "H Wv.d. Sanden" & tax == 5.32)]


# ------------------------------------------------------------------------------
# MOVERS: RESOLVE ADDRESS MOVES WITHIN TAX YEAR
# ------------------------------------------------------------------------------
# should move c. 9000 households
dim(tax)
source("./src/moves.R")
dim(tax)


do_cross_sheet_duplicates = FALSE
dim(tax)
source("./src/households.R")
dim(tax)

# --------------------------------------------------------
# fix deductions/gross/taxable on a per municipality basis
# --------------------------------------------------------
tax[income_taxable > 0, taxrate := tax / income_taxable]

dim(tax)
source("./src/munic_income_fixes.R")
dim(tax)

# -------------------------------
# check tax rates
# -------------------------------

tax[income_taxable > 0, pct := tax / income_taxable]
tax[order(-income_taxable), list(year_mun_id, income_taxable, tax, taxrate)]
tax[order(-pct), list(year_mun_id, income_taxable, tax, pct)][1:20]
# so clearly more fixing to be done...

plot(tax ~ income_taxable, data = tax, log = "xy")
curve(1*x, add = TRUE)
curve(0.1 * x, add = TRUE)
curve(0.01 * x, add = TRUE)
curve(0.005 * x, add = TRUE)
# so all these taxes still need fixing if you're ever to use that data


# above covers tax > income_gross
# but this still needs addressed
# tax[tax > income_taxable, list(year_mun_id, sheet_name, volgnummer, income_gross, income_taxable, tax)]
# tax[income_taxable > income_gross, list(year_mun_id, sheet_name, volgnummer, income_gross, income_taxable, tax)]

# implement deductions if present
# should only do one obs in woubrugge 1919
tax[is.na(income_gross) & !is.na(income_taxable) & !is.na(deductions), income_gross := income_taxable + deductions]

# TODO: use the raad incomes which should be better if present, but be careful whether it's taxable or gross
# also a munic-by-munic thing

# ---------------------------------------------
# transfer mid to gross or taxable
# ---------------------------------------------

# all obvious gross and taxable filled, these remain
# tax[year_mun_id == "1889_Philippine", ..inspvrbs][order(mid)] # twijfelgeval
# tax[year_mun_id == "1879_Zierikzee", ..inspvrbs][order(mid)] # low but 1909 taxable lower...
# tax[year_mun_id == "1889_Zierikzee", ..inspvrbs][order(mid)] # low but 1909 taxable lower...
# tax[year_mun_id == "1899_Zierikzee", ..inspvrbs][order(mid)] # low but 1909 taxable lower...
# tax[year_mun_id == "1879_Hulst", ..inspvrbs][order(mid)] # twijfelgeval (200) but maybe zeeland is just generally low?

tax[, transfer_mid_to_taxable := min(mid, na.rm = TRUE) < 300 & is.na(income_taxable) & !is.na(mid), by = year_mun_id]
tax[transfer_mid_to_taxable == TRUE, list(.N, min(mid)), by = year_mun_id]
tax[transfer_mid_to_taxable == TRUE, income_taxable := mid]

# ---------------------------------------------
# fix low incomes
# ---------------------------------------------

# some incomes are very low, we suspect these are taxable incomes without
# mentioning it; these we fix, making sure it's applied to the full distribution

pdf("./fig/ridge_by_prov.pdf", height = 10)
for (prov in unique(tax$province)){
    toplot = tax[dec > 1860 & income_gross > 0 & province == prov]
    plt(dec ~ log(income_gross), data = toplot, type = "ridge", main = paste(prov, "gross"))
    abline(v = log(c(200, 300, 400, 500)))
}
dev.off()

toplot = tax[!is.na(income_gross), as.list(quantile(income_gross, c(0, 0.05, 0.1, 0.15, 0.2, 0.25, 0.3))), by = list(province, dec)]
toplot[order(province, dec)]
# zh: 400 ... 500
# ov just check, don't touch
# dr+lim 200? 450

# implement correction

tocorrect = tax[!is.na(income_gross), quantile(income_gross, 0.1), by = list(province, dec, year_mun_id)]
low_munic_pre1920_ld = tocorrect[province %in% c("Drenthe", "Limburg") & dec < 1920 & V1 < 250]
low_munic_pre1920 = tocorrect[!province %in% c("Drenthe", "Limburg") & dec < 1920 & V1 < 300]
low_munic_1920_ld = tocorrect[province %in% c("Drenthe", "Limburg") & dec == 1920 & V1 < 400]
low_munic_1920 = tocorrect[!province %in% c("Drenthe", "Limburg") & dec == 1920 & V1 < 500]

tocorrect[order(dec)][grepl("Waalwijk", year_mun_id)]
tocorrect[order(dec)][grepl("Enschede", year_mun_id)]

low_munic_pre1920_ld[, correct := 250 - V1]
low_munic_pre1920[, correct := 300 - V1]
low_munic_1920_ld[, correct := 450 - V1]
low_munic_1920[, correct := 500 - V1]

tomerge = rbind(
    low_munic_pre1920_ld,
    low_munic_pre1920,
    low_munic_1920_ld,
    low_munic_1920
)
tomerge[duplicated(year_mun_id)]
dim(tax)
tax = merge(tax, tomerge[, list(year_mun_id, correct)], by = "year_mun_id", all.x = TRUE)
dim(tax)
tax[!is.na(correct), income_gross := income_gross + correct]
tax[!is.na(correct), .N]
tax[, uniqueN(year_mun_id), by = !is.na(correct)]

# 41 corrections, 
# TODO: CHECK THEM one by one
tax[, correct := NULL]


# we still have 25-100 observations which are low
tax[income_gross < 200]
tax[income_gross < 250]
# but these are typically in munics with a solid q10 or q05
tax[!is.na(income_gross), list(min(income_gross), quantile(income_gross, 0.05), quantile(income_gross, 0.1)), by = year_mun_id][
    V1 < 200]
tax[!is.na(income_gross), list(min(income_gross), quantile(income_gross, 0.05), quantile(income_gross, 0.1)), by = year_mun_id][
    V1 < 250]

# so, another HEAVEYHANDED correction, here it is assumed these are individuals outliers, not full distributions
tax[income_gross < 250, income_gross := 250]

# by urb, by prov

# pdf("~/repos/hipnl/img/63check.pdf", height = 6)
# for (mun in unique(toplot$municipality)){
#     plt(value ~ year | q, data = toplot[municipality == mun], type = "b", main = mun)
#     abline(h = c(200, 300, 400, 500))
# }
# dev.off()

# ---------------------------------------------
# prep for modelling
# ---------------------------------------------

# log and predict 2x2x
# urban dummy
t17 = tax[, .N, by = list(amco, year_mun_id)][order(-N)][1:17, amco]
tax[, urban := as.integer(amco %in% t17)]
tax[, nhh := .N, by = year_mun_id]
# [1] "Utrecht"    "Enschede"   "Leiden"     "Nijmegen"   "Amersfoort"
# no edam, waalwijk, eindhoven

tax[income_taxable > 0, taxrate := tax / income_taxable]
tax[income_gross > 0, taxrate_gross := tax / income_gross]
# TODO: some 500 tax observations are quite high; some clearly wrong, some plausible but need checking
tax[, high_taxrate := (taxrate > 0.2 | taxrate_gross > 0.2)]
tax[is.na(high_taxrate), high_taxrate := FALSE]
# these we drop below when making tomod

tax[income_gross >= 0, lincome_gross := log(income_gross)]
tax[income_taxable >= 0, lincome_taxable := log1p(income_taxable)]
tax[income_unspecified >= 0, lincome_unspecified := log1p(income_unspecified)]
tax[mid >= 0, lmid := log1p(mid)]
tax[, lmid := log1p(mid)]
tax[, ltax := log1p(tax)]

tax[!is.na(tax), q10tax := log(quantile(tax, 0.1)), by = year_mun_id]

tax[, n_in_household := .N, by = global_hhid]
tax[, .N, by = n_in_household]

# munic, prov, dec dummies for xgboost
ids = unique(tax$amco)
tax[, (paste0("a", ids)) := lapply(ids, function(x) as.integer(amco == x))]
ids = unique(tax$province)
tax[, (paste0("dprov", ids)) := lapply(ids, function(x) as.integer(province == x))]
ids = unique(tax$dec)
tax[, (paste0("y", ids)) := lapply(ids, function(x) as.integer(dec == x))]

# train/test split
set.seed(4753)
share_train = 0.7
tax[, train := rbinom(.N, 1, prob = share_train), by = year_mun_id]
# # original, dummies
# trn = tax[train == 1 & income_taxable >= 0 & income_gross >= 0, .SD, .SDcols = patterns("linc|ltax|lmid|n_children$|top|a\\d+|y\\d+")]
# vld = tax[train == 0 & income_taxable >= 0 & income_gross >= 0, .SD, .SDcols = patterns("linc|ltax|lmid|n_children$|top|a\\d+|y\\d+")]
# no waalwijk data
tax[municipality == "Waalwijk"]
tax[, waalwijk := as.integer(a11359)]

# no waalwijk, no enschede
# trn = tax[train == 1 & income_taxable >= 0 & income_gross >= 0 & municipality != "Waalwijk" & year_mun_id != "1919_Enschede", .SD, .SDcols = patterns("linc|ltax|lmid|n_children$|top|a\\d+|y\\d+")]
# vld = tax[train == 0 & income_taxable >= 0 & income_gross >= 0 & municipality != "Waalwijk" & year_mun_id != "1919_Enschede", .SD, .SDcols = patterns("linc|ltax|lmid|n_children$|top|a\\d+|y\\d+")]

# ptrn = "linc|ltax|lmid|n_children$|top|dprov|y\\d+|urb|q10tax"
ptrn = "linc|lmid|n_children$|top|dprov|y\\d+|urb|q10tax|n_in_household"

tax[, .N, by = high_taxrate]
# all there, munic dummies
trn = tax[train == 1 & income_taxable >= 0 & income_gross >= 0 & high_taxrate == FALSE, .SD, .SDcols = patterns(ptrn)]
vld = tax[train == 0 & income_taxable >= 0 & income_gross >= 0 & high_taxrate == FALSE, .SD, .SDcols = patterns(ptrn)]
# trn = tax[train == 1 & income_taxable >= 0 & income_gross >= 0, .SD, .SDcols = patterns("linc|ltax|lmid|n_children$|top|dprov|y\\d+|aalwijk|urb")]
# vld = tax[train == 0 & income_taxable >= 0 & income_gross >= 0, .SD, .SDcols = patterns("linc|ltax|lmid|n_children$|top|dprov|y\\d+|aalwijk|urb")]

# some sumstats
tax[train == 1 & income_taxable >= 0 & income_gross >= 0 & high_taxrate == FALSE, .N, by = list(year_mun_id, dec)]
tax[train == 1 & income_taxable >= 0 & income_gross >= 0 & high_taxrate == FALSE, as.list(summary(income_gross)), by = list(year_mun_id, dec)][1:20]
tax[train == 1 & income_taxable >= 0 & income_gross >= 0 & high_taxrate == FALSE, as.list(summary(income_gross)), by = list(dec)]
tax[train == 1 & income_taxable >= 0 & income_gross >= 0 & high_taxrate == FALSE, as.list(summary(income_taxable)), by = list(dec)]

# this makes performa
# trn = unique(trn)
# vld = unique(vld)

# tax[!is.na(income_gross) & dec == 1870, .N, by = year_mun_id]
# tax[!is.na(income_gross) & dec == 1870, range(income_gross), by = year_mun_id]
# tax[!is.na(income_gross) & dec == 1860, range(income_gross), by = year_mun_id]
# tax[!is.na(income_gross) & dec == 1880, range(income_gross), by = year_mun_id]

trn_xgbm = xgboost::xgb.DMatrix(as.matrix(trn[, -"lincome_gross"]), label = as.matrix(trn$lincome_gross))
vld_xgbm = xgboost::xgb.DMatrix(as.matrix(vld[, -"lincome_gross"]), label = as.matrix(vld$lincome_gross))

m = xgboost::xgb.train(
    data = trn_xgbm,
    nrounds = 500,
    watchlist = list(train = trn_xgbm, eval = vld_xgbm),
    params = list(
        # max_depth = 6,        # default 6
        # min_child_weight = 1, # default 1
        # gamma = 1,            # default 0
        eta = 0.2,            # default 0.3 lower for less overfitting
        # subsample = 0.8,        # default 1 lower for less overfitting
        # colsample_bytree = 0.5, # default 1
        objective = "reg:squarederror"
))
# used to be [500]   train-rmse:0.054416 eval-rmse:0.073647 
# no mun or prov 0.098183
# with prov 0.098183
# with prov urb 0.095883
# with prov urb q10tax 0.080579
# with actual prov .076
# with actual prov .074 with some selection
# with actual prov .077 with missing children to zero (used to be 0.076 again)
# setting it unique worsens performance to 0.12
# with tax mistakes fixed, 0.074
# not using tax: 0.078 (so actually we want to fix all taxes but here we are)
# not using tax and n_in_household: 0.077

xgb.importance(model = m)

toplot =  data.table(
    m$evaluation_log$train_rmse,
    m$evaluation_log$eval_rmse
)
matplot(toplot[-c(1:10)])

predictions = data.table(
    vld,
    actual = vld$lincome_gross,
    predicted = predict(m, vld_xgbm)
)

# maybe drop 1920 for this?
# modmat = copy(tax)
# modmat[, lincome_taxable := NA]
# modmat[, lincome_unspecified := NA]

# set.seed(4753)
# # train/test split
# share_train = 0.7
# modmat[, train := rbinom(.N, 1, prob = share_train), by = year_mun_id]
# old (6.0.0 approach, drops )
# trn = modmat[train == 1 & income_taxable >= 0 & income_gross >= 0 & municipality != "Waalwijk" & year_mun_id != "1919_Enschede", .SD, .SDcols = patterns("linc|ltax|lmid|n_children$|top|a\\d+|y\\d+")]
# vld = modmat[train == 0 & income_taxable >= 0 & income_gross >= 0 & municipality != "Waalwijk" & year_mun_id != "1919_Enschede", .SD, .SDcols = patterns("linc|ltax|lmid|n_children$|top|a\\d+|y\\d+")]

# drop tax is NA, adds a lot of noise, this is enschede 1919, 
# trn = modmat[train == 1 & income_taxable >= 0 & income_gross >= 0 & tax >= 0, .SD, .SDcols = patterns("linc|ltax|lmid|n_children$|top|a\\d+|y\\d+")]
# vld = modmat[train == 0 & income_taxable >= 0 & income_gross >= 0 & tax >= 0, .SD, .SDcols = patterns("linc|ltax|lmid|n_children$|top|a\\d+|y\\d+")]

# reset pattern because above we did not have
ptrn = "linc|ltax|lmid|n_children$|top|dprov|y\\d+|urb|q10tax|n_in_household"

trn = tax[train == 1 & tax >= 0 & income_gross >= 0 & high_taxrate == FALSE, .SD, .SDcols = patterns(ptrn)]
vld = tax[train == 0 & tax >= 0 & income_gross >= 0 & high_taxrate == FALSE, .SD, .SDcols = patterns(ptrn)]


# easier way
trn[, lincome_taxable := NA]
trn[, lincome_unspecified := NA]
trn = trn[exp(ltax) > 0]
vld[, lincome_taxable := NA]
vld[, lincome_unspecified := NA]
vld = vld[exp(ltax) > 0]

# xgboost matrix format
trn_xgbm = xgboost::xgb.DMatrix(as.matrix(trn[, -"lincome_gross"]), label = as.matrix(trn$lincome_gross))
vld_xgbm = xgboost::xgb.DMatrix(as.matrix(vld[, -"lincome_gross"]), label = as.matrix(vld$lincome_gross))

m_tax = xgboost::xgb.train(
    data = trn_xgbm,
    nrounds = 500,
    watchlist = list(train = trn_xgbm, eval = vld_xgbm),
    params = list(
        # max_depth = 6,        # default 6
        # min_child_weight = 1, # default 1
        # gamma = 1,            # default 0
        eta = 0.2,            # default 0.3 lower for less overfitting
        # subsample = 0.8,        # default 1 lower for less overfitting
        # colsample_bytree = 0.5, # default 1
        objective = "reg:squarederror"
))


# [500]   train-rmse:0.098483 eval-rmse:0.125739 
# 0.129065
# 0.128 with actual prov
# 0.124 with some data fixes 
# 0.1205 with amersfoort
# 0.1150 with tax mistakes fixed
# bunch of tax fixes, 0.105
# bunch of tax fixes, 0.107 after new round
# bunch of tax fixes, 0.1069 n_in_household

predictions_tax = data.table(
    vld,
    actual = vld$lincome_gross,
    predicted = predict(m_tax, vld_xgbm))

# new modelling ideas
# reasonable min value (q10?) for province x decade
# linear model income_gross ~ tax + i(year) + i(prov) + etc. to get hard taxes

library("fixest")
trn = tax[lincome_gross > 0 & tax > 0 & train == 1 & high_taxrate == FALSE, list(lincome_gross, ltax, dec, nhh, urban, q10tax, province)]
vld = tax[lincome_gross > 0 & tax > 0 & train == 0 & high_taxrate == FALSE, list(lincome_gross, ltax, dec, nhh, urban, q10tax, province)]
m1 = feols(lincome_gross ~ ltax + i(dec) + i(province) + urban + q10tax, data = trn)
etable(m1)

# ok so what's basically happening is that the all the deductions at the lower
# end of the range are pulling the slope and intercept down a lot, so much so
# that the implication is that there are lower tax rates in the 1920s. This
# is not the case, but there you have it. For now, I'm just running with it,
# but maybe we should just straight-up use this:
tax[, mean(tax / income_gross, na.rm = TRUE), by = list(dec)]
tax[, mean(tax / income_gross, na.rm = TRUE), by = list(province, dec)][order(dec)]

predictions_lm = data.table(
    vld,
    actual = vld$lincome_gross,
    predicted = predict(m1, newdata = vld)
)

# rsme
predictions_lm[, sqrt(mean((predicted - actual)^2))] # considerably worse than xgb


# NA taxes
# tax[year_mun_id == "1920_Zaandijk" & is.na(tax), 1:40] # there are just lots of non-taxed individuals in the data here
# tax[year_mun_id == "1909_Varik" & is.na(tax), 1:40] # lots of empty rows in original with a volgnummer
# tax[year_mun_id == "1899_Varik" & is.na(tax), notes_register] # there are all no tax cases
# tax[year_mun_id == "1869_Vaals" & is.na(tax), 1:30] # this just has gaps, no-pays I think
# tax[year_mun_id == "1899_Hindeloopen" & is.na(income_taxable), 1:30] # this just has gaps, no-pays I think

# tax[year_mun_id == "1919_Enschede"]
tax[, noinc := is.na(income_gross) & is.na(income_taxable) & is.na(tax)]
tax[, list(sum(noinc), mean(noinc), .N), by = year_mun_id][order(V2)]
# q though is: what do you do with these? 
# drop them and then impute? seems best

totab = xgboost::xgb.importance(model = m)
knitr::kable(totab[1:13], digits = 3)
totab = xgboost::xgb.importance(model = m_tax)
knitr::kable(totab[1:13], digits = 3)
etable(m1, digits = 3)

pdf("./fig/income_harmonisation_63.pdf", height = 5, width = 10)
par(mfrow = c(1, 3))
plot(predicted ~ actual,
    data = predictions, col = 2, pch = 19, 
    main = "xgb w. taxable incomes",
    xlab = "actual gross income (fl.)", 
    ylab = "predicted gross income (fl.)")
curve(1*x, add = TRUE)
plot(predicted ~ actual,
    predictions_tax, col = 2, pch = 19, 
    main = "xgb w/o taxable incomes",
    xlab = "actual gross income (fl.)", 
    ylab = "predicted gross income (fl.)")
curve(1*x, add = TRUE)
plot(predicted ~ actual,
    predictions_lm, col = 2, pch = 19, 
    main = "linear w/o taxable incomes",
    xlab = "actual gross income (fl.)", 
    ylab = "predicted gross income (fl.)")
curve(1*x, add = TRUE)
dev.off()

# insert predictions into tax records and track source
tax[!is.na(income_taxable), income_predicted_xgb := exp(predict(m, newdata = xgboost::xgb.DMatrix(as.matrix(.SD)))), .SDcols = m$feature_names]
tax[!is.na(income_taxable), source := "xgb income model"]
### ! ### aren't there more relevant classes here 

tax[is.na(income_taxable), income_predicted_xgb := exp(predict(m_tax, newdata = xgboost::xgb.DMatrix(as.matrix(.SD)))), .SDcols = m_tax$feature_names]
tax[is.na(income_taxable), source := "xgb tax only model"]
tax[dec > 1850, income_predicted_lin := exp(predict(m1, newdata = .SD))]
tax[is.na(income_taxable), source_lin := "lm tax only model"]

# original gross estimate if we have it
tax[, income_predicted_xgb := ifelse(is.na(income_gross), income_predicted_xgb, income_gross)]
tax[, income_predicted_lin := ifelse(is.na(income_gross), income_predicted_lin, income_gross)]
tax[, income_predicted_cbn := fcase(
    !is.na(income_gross), income_gross,
    !is.na(income_taxable) & is.na(income_gross), income_predicted_xgb,
    is.na(income_taxable) & is.na(income_gross), income_predicted_lin,
    default = income_predicted_lin
)]
tax[!is.na(income_gross), source := "original data"]
tax[!is.na(income_gross), source_lin := "original data"]

# lin and xgb disagreements 
# lot of 1879 utrecht which is that weird rijksopcenten thing
tax[income_predicted_lin < 30e3 & income_predicted_xgb > 60e3, list(year_mun_id, sheet_name, wijk, volgnummer, income_predicted_lin, income_predicted_xgb, income_taxable, tax)]

mypar(mfrow = c(1,1))
plt(income_predicted_xgb ~ income_taxable | factor(dec), data = tax[dec < 1920 & is.na(income_gross)], log = "xy")
curve(1*x, add = TRUE)
curve(1*x + 500, add = TRUE)
curve(1*x + 1000, add = TRUE)
# see also above, some weird taxable > gross, that bunch of weird 1880 outliers, this all needs fixed
grid()

# the outlier predictions are mostly in doniawerstal and utrecht 1870, two known problematic taxes
tax[income_taxable < 1e3 & (income_taxable + 1000) < income_predicted_xgb & dec == 1870,
    list(year_mun_id, sheet_name, wijk, volgnummer, income_predicted_lin, income_predicted_xgb, income_taxable, tax)] [
    , .N, by = year_mun_id]
# TODO: address this, first check the data

# TODO: Here gross and taxable do not make sense, check and fix
tax[income_taxable > income_gross & income_taxable > 1e4, list(year_mun_id, dec, income_taxable, income_gross, income_gross - income_taxable)]

fwrite(tax, 
    file = "~/data/hipnl-processed/tax_wpredictions_v631_2.0_moves_households.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_1.12_maskedtaxes.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_1.10_taxtyposfixes.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_1.9_waalwijkfix.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_1.8_amersfoortfix.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_1.7_kids_names.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_1.6_lingross.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_1.5_noinc.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_1.4_eindhoven.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_1.3_lowerbounds.csv"
)
