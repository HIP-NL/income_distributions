rm(list = ls())

library("EnvStats")
library("data.table")
library("tinyplot")

source("https://raw.githubusercontent.com/HIP-NL/imputations/refs/heads/master/impute.R")
source("./src/functions.R")

tax_records_path = "~/data/hipnl-processed/"

tax = fread(
    file = file.path(tax_records_path, "tax_wpredictions_v631_2.0_moves_households.csv")
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_2.0_moves_households.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_1.12_maskedtaxes.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_1.10_taxtyposfixes.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_1.9_waalwijkfix.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_1.7_kids_names.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_1.6_lingross.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_1.5_noinc.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_1.4_eindhoven.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631_1.3_lowerbounds.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions_v631.csv"
    # file = "~/data/hipnl-processed/tax_wpredictions.csv"
)

# should happen earlier in cleaning file or better yet it's nver part of the full db
tax[, `getal_personen_waaruit_elk_gezin_bestaat` := NULL]
tax[, `income_capital (\"\"geraamd door raad\"\", onderdeel a)` := NULL]
tax[, `income_other (\"\"geraamd door raad\"\", ondeel b)` := NULL]
tax[, `totaal berekening eerste grondslag` := NULL]

tax[, amco_year := paste0(amco, "_", year)]
tax[, i := NULL]
tax = tax[dec  > 1850]

pop = fread(
    file = "~/repos/hipnl/dat/refpop_pred_63.csv"
)
pop = pop[municipality != "het Bildt"]


# price index
priceindex = fread("~/repos/hipnl/dat/priceindex.csv")
priceindex[ , index1900 := index / mean(index[between(year, 1895, 1905)])]
priceindex[, index1900_smth := frollmean(index1900, 3, align = "right", algo = "exact")]
priceindex[, index1900_smth := frollmean(index1900, 5, align = "center", algo = "exact")]

# minimum incomes in the imputation procedure
tax[, minimum_income := fcase(
    province %in% c("Drenthe", "Limburg")       & dec <  1920, 250,
    ( !province %in% c("Drenthe", "Limburg") )  & dec <  1920, 300,
    province %in% c("Drenthe", "Limburg")       & dec == 1920, 450,
    ( !province %in% c("Drenthe", "Limburg") )  & dec == 1920, 500
)]

# impute predicted_incomes directly
imputelist = list()
lengthlist = list()
i = "10722_1879"

# suggestion: just drop missing income_predicted_cbn as these should be treated via refpop
tax[is.na(income_predicted_cbn), .N]
tax[is.na(tax) & is.na(income_taxable) & is.na(income_gross), .N]
# max drops 10% in a handful of villages

tax = tax[!is.na(income_predicted_cbn)]

# aggregate to households
tax[, income_predicted_cbn := sum(income_predicted_cbn), by = global_hhid]
tax[, income_predicted_lin := sum(income_predicted_lin), by = global_hhid]
tax[, income_predicted_xgb := sum(income_predicted_xgb), by = global_hhid]
tax = tax[!duplicated(global_hhid)]

set.seed(54123)
unique_amco_years = unique(tax$amco_year)
for (i in unique_amco_years){
    print(i)

    # subset tax data

    tax_ss = tax[amco_year == i]
    print(tax_ss[1, list(year, municipality)])

    minimum_income = unique(tax_ss$minimum_income) * 0.4
    # get amco cbs year
    cbs_amco_year_ss = tax_ss[, paste0(unique(amco), "_", unique(cbs_year))]
    dec_ss = tax_ss[, unique(dec)]
    amco_ss = tax_ss[, unique(amco)]
    
    # get reference population, here simply households
    # some households
    refpop = pop[amco == amco_ss & dec == dec_ss][1, households]
    # refpop = pop[amco_year == cbs_amco_year_ss, refpop_hh_pred_combined]

    
    # if we have more tax observations than the reference population, don't impute
    if (refpop <= nrow(tax_ss)){
        imputelist[[i]] = tax_ss
    } else {
        
        # impute xgb predcitions
        print(min(tax_ss$income_predicted_xgb))
        print(quantile(tax_ss$income_predicted_xgb, 0.01, na.rm = TRUE))

        imputed_incomes_xgb = sample_from_lognormal(
            tax_ss$income_predicted_xgb, 
            n_missing = refpop - nrow(tax_ss),
            min = minimum_income # 50
        )
        # keep imputations only
        imputed_incomes_xgb = imputed_incomes_xgb[-c(1:sum(!is.na(tax_ss$income_predicted_xgb)))]


        # impute linear predictions but only if all present
        
        # big cities only, but still don't want all NA surely? CHECK
        if (all(is.na(tax_ss$income_predicted_lin))){
            imputed_incomes_lin = rep(NA, refpop - nrow(tax_ss))
        } else {
            # drop NA as (i) they are usually too low to be taxed and should be imputed and (ii) they cannot be estimated
            toimpute = tax_ss$income_predicted_lin[!is.na(tax_ss$income_predicted_lin)]
            imputed_incomes_lin = sample_from_lognormal(
                toimpute, 
                n_missing = refpop - nrow(tax_ss), # to make sure no imputed incomes are omitted, but that means too few are included. Fix by having separate data structures or overwriting the NAs?
                min = minimum_income # 50
            )            
            # keep imputations only
            imputed_incomes_lin = imputed_incomes_lin[-c(1:sum(!is.na(tax_ss$income_predicted_lin)))]
        }

        # impute cbn incomes, like linear
        if (all(is.na(tax_ss$income_predicted_cbn))){
            imputed_incomes_cbn = rep(NA, refpop - nrow(tax_ss))
        } else {
            toimpute = tax_ss$income_predicted_cbn[!is.na(tax_ss$income_predicted_cbn)]
            imputed_incomes_cbn = sample_from_lognormal(
                toimpute, 
                n_missing = refpop - nrow(tax_ss), # to make sure no imputed incomes are omitted, but that means too few are included. Fix by having separate data structures or overwriting the NAs?
                min = minimum_income # 50
            )                        
            imputed_incomes_cbn = imputed_incomes_cbn[-c(1:sum(!is.na(tax_ss$income_predicted_cbn)))]
        }
        # }

        # first n incomes are the originals
        # imputed_incomes_xgb = imputed_incomes_xgb[-c(1:nrow(tax_ss))]
        # imputed_incomes_lin = imputed_incomes_lin[-c(1:nrow(tax_ss))]
        # imputed_incomes_cbn = imputed_incomes_cbn[-c(1:nrow(tax_ss))]


        print(length(imputed_incomes_xgb))
        print(length(imputed_incomes_lin))
        print(length(imputed_incomes_cbn))

        tax_imputed = rbindlist(list(
            tax_ss,
            data.table(income_predicted_xgb = imputed_incomes_xgb,
                       income_predicted_lin = imputed_incomes_lin,
                       income_predicted_cbn = imputed_incomes_cbn,
                       amco_year = i,
                       imputed = TRUE,
                       refpop = refpop,
                       index1900 = tax_ss$index1900[1],
                       occupation = "imputed")),
            fill = TRUE)
        imputelist[[i]] = tax_imputed
        # lengthlist[[i]] = list(
        #     length(imputed_incomes_xgb),
        #     length(imputed_incomes_lin),
        #     length(imputed_incomes_cbn)
        # )
    }
}

# warnings concern linear predictions, makes sense because sometimes tax is missing
txi = rbindlist(lapply(imputelist, data.table), idcol = "amco_year2", fill = TRUE)
txi = rbindlist(imputelist, idcol = "amco_year2", fill = TRUE)
txi[is.na(imputed), imputed := FALSE]

# fill variables
txi[, dec := nafill(dec, type = "locf"), by = amco_year]
txi[, c("amco", "year") := tstrsplit(amco_year, "_")]
txi[, amco := as.integer(amco)]
txi[, year := as.integer(year)]
txi[, municipality := na.omit(municipality)[1], by = amco_year]
txi[, year_mun_id := na.omit(year_mun_id)[1], by = amco_year]
txi[, province := na.omit(province)[1], by = amco_year]
txi[, refpop := na.omit(refpop)[1], by = amco_year]

# fill in missing refpop from N, after refpop propagation above (so all-na cases only)
txi[, refpop_alt := .N, by = year_mun_id]
txi[is.na(refpop), refpop := refpop_alt]
txi[, refpop_alt := NULL]

# useful variables
# female was only entered if yes, so fill rest
txi[is.na(female) & imputed == FALSE, female := 0]
txi[female == 2, female := 1] # fixes typo

txi[, widow := as.integer(grepl("\\b[Ww]ed?", title))]
txi[maritalstatus == "w", widow := 1]
txi[grepl("\\b[Ww]ed", notes_register), widow := 1]

# apply deflator
# this should happen in previous script, really, but then you have more 
txi = merge(txi, priceindex, by = "year")
txi[, income_predicted_xgb_1900 := income_predicted_xgb / index1900_smth]
txi[, income_predicted_lin_1900 := income_predicted_lin / index1900_smth]
txi[, income_predicted_cbn_1900 := income_predicted_cbn / index1900_smth]

# this version fixes that y > y_q is a weird number when y_q is a big block

pdf("./fig/ineq_v631.pdf", height = 6)
mypar()
txi[, ineq::Gini(income_predicted_xgb), by = dec] |> plot(ylim = c(0.35, 0.75), type = "b")
txi[, ineq::Gini(income_predicted_lin), by = dec] |> points(, type = "b", col = 2)
txi[, ineq::Gini(income_predicted_cbn), by = dec] |> points(, type = "b", col = 3)
txi[imputed == FALSE, ineq::Gini(income_predicted_xgb), by = dec] |> points(col = 4, type = "b")
txi[imputed == FALSE, ineq::Gini(income_predicted_lin), by = dec] |> points(ylim = c(0.4, 0.75), type = "b", col = 5)
txi[imputed == FALSE, ineq::Gini(income_predicted_cbn), by = dec] |> points(ylim = c(0.4, 0.75), type = "b", col = 6)
legend("topright", fill = 1:6, 
    legend = c(
        "w imps, xgb",
        "w imps, lin",
        "w imps, cbn",
        "w/o imps, xgb",
        "w/o imps, lin",
        "w/o imps, cbn"
    )
)
dev.off()

# weird 1870 bump has a lin/xgb discrepancy
txi[dec == 1870 & imputed == FALSE, 
    list(cbn = mean(income_predicted_cbn, na.rm = TRUE), 
         lin = mean(income_predicted_lin, na.rm = TRUE)), by = municipality][order(cbn/lin)]
# all the remaining weird is utrecht 1870
# maybe it's the very low taxrates doing this
# TODO: check what's going on with Utrecht 1870

txi[dec == 1880 & imputed == FALSE, 
    list(cbn = mean(income_predicted_cbn, na.rm = TRUE), 
         lin = mean(income_predicted_lin, na.rm = TRUE)), by = municipality][order(cbn/lin)]
# Utrecht
# Uden
# Loenen

txi[dec == 1920 & imputed == FALSE, 
    list(cbn = mean(income_predicted_cbn, na.rm = TRUE), 
         lin = mean(income_predicted_lin, na.rm = TRUE)), by = municipality][order(cbn/lin)]
# Utrecht
# Uden
# Loenen
 
## some sumstats on the db

toplot = txi[, mean(!imputed), by = dec][order(dec)]
pdf("./fig/coverage_aug2025_v63.pdf", height = 6)
mypar()
plot(toplot, type = "b", pch = 19, col = 2,
    xlab = "year", ylab = "share households covered", 
    ylim = c(0.5, 1))
dev.off()

pdf("./fig/nhh_aug2025_v63.pdf", height = 6)
toplot = txi[year > 1850, sum(!imputed), by = dec][order(dec)]
mypar()
plot(toplot, type = "b", pch = 19, col = 2,
    xlab = "year", ylab = "N. households in tax data")
dev.off()

pdf("./fig/implied_hh_aug2025_v63.pdf", height = 6)
toplot = txi[year > 1850, .N, by = dec][order(dec)]
mypar()
plot(toplot, type = "b", pch = 19, col = 2,
    xlab = "year", ylab = "Total households covered by data")
dev.off()

pdf("./fig/nreg_aug2025_v63.pdf", height = 6)
toplot = txi[year > 1850, uniqueN(amco), by = dec][order(dec)]
mypar()
plot(toplot, type = "b", pch = 19, col = 2,
    xlab = "year", ylab = "N. municipalities")
dev.off()

# ----------------------------------------------------------
# synthetic full municipalitiesby interpolating percentiles
# ----------------------------------------------------------

# first, make imputation grid

# these are all double, so don't put them in the grid
skip = c("1899_Zuidwolde", "1920_Wilnis", "1869_Bunnik")

impgrid = unique(tax[!year_mun_id %in% skip, list(dec, year, municipality, amco, amco_year, year_mun_id)])
# only do this for munics with a least 3 obs
impgrid[, n_year := .N, by = municipality]
impgrid = impgrid[n_year > 3]
impgrid = merge(
    impgrid,
    impgrid[, CJ(dec, municipality, unique = TRUE)],
    all.y = TRUE,
    by = c("dec", "municipality")
)

impgrid[, should_impute := is.na(year)]
impgrid[, amco := na.omit(amco)[1], by = municipality]
impgrid[, n_year := na.omit(n_year)[1], by = municipality]
impgrid[is.na(year) & dec < 1920, year := dec - 1]
impgrid[is.na(year) & dec == 1920, year := dec]


impgrid[, uniqueN(amco_year)]
impgrid[, sum(should_impute)]

# check with refpop

impgrid[is.na(amco_year), amco_year := paste0(amco, "_", year)]
impgrid[, uniqueN(year_mun_id)]
impgrid[is.na(year_mun_id), year_mun_id := paste0(year, "_", municipality)]
impgrid[, uniqueN(year_mun_id)]
impgrid[order(municipality), list(year_mun_id, should_impute)] |> as.data.frame()
dim(impgrid)
impgrid = merge(
    impgrid,
    pop[, list(amco_year, pop_31_12, households)],
    by = "amco_year",
    all.x = TRUE,
    all.y = FALSE
)
dim(impgrid)
sum(is.na(impgrid$households)) == 0

# the percentiles
probs = 0:100/100

# quantiles for each municipality in imputed dataset
quantile_grid = txi[, quantile(income_predicted_cbn_1900, probs, na.rm = TRUE), by = list(year_mun_id, municipality, year)]
quantile_grid[, q := rep(probs, times = uniqueN(year_mun_id))]

# grid to impute on, based on original impgrid above (> 3 data)
impgridq = impgrid[, list(q = probs), by = list(year_mun_id, municipality, year)]
impgridq = merge(impgridq, quantile_grid, by = c("year_mun_id", "municipality", "year", "q"), all = TRUE)

# bookkeeping of source data: V1 present is actual data
impgridq[!is.na(V1), source := "original"]

# order by year to ensure correct iterpolation
setorder(impgridq, municipality, year, q)
# interpolate each quantile
impgridq[, 
    income_interpolated := exp(zoo::na.approx(log(V1), x = year, na.rm = FALSE)), 
    by = list(municipality, q)]
# source if V1 missing and ip present
impgridq[is.na(V1) & !is.na(income_interpolated), source := "interpolated"]

# highlight forward imputes
impgridq[, obs := !is.na(V1)]
impgridq[, to_extrapolate_fwd := !obs & data.table::shift(obs, 1) & data.table::shift(obs, 2) & data.table::shift(obs, 3), by = list(municipality, q)]
impgridq[source == "interpolated", to_extrapolate_fwd := FALSE]
# data for imputation
impgridq[, imputeblock_fwd := shift(to_extrapolate_fwd, type = "lead", 0:3) |> as.data.frame() |> rowSums(na.rm = TRUE), by = list(municipality, q)]

# highlight backwards imputes
impgridq[order(-year), to_extrapolate_bck := 
    !obs & shift(obs, 1) & shift(obs, 2) & shift(obs, 3),
    by = list(municipality, q)]
impgridq[source == "interpolated", to_extrapolate_bck := FALSE]
impgridq[order(-year), imputeblock_bck := shift(to_extrapolate_bck, type = "lead", 0:3) |> as.data.frame() |> rowSums(na.rm = TRUE), by = list(municipality, q)]

impgridq[to_extrapolate_bck == TRUE, list(year, municipality)][order(year)] |> unique()

# highlight 2x backwards imputes (to fit with weighted regression)
impgridq[order(-year), to_extrapolate_bck2 := 
    !obs & shift(!obs, 1) & shift(obs, 2) & shift(obs, 3) & shift(obs, 4), # here we also allow xx000 to impute 1870
    by = list(municipality, q)]
impgridq[source == "interpolated", to_extrapolate_bck2 := FALSE]
impgridq[order(-year), imputeblock_bck2 := shift(to_extrapolate_bck2, type = "lead", 0:4) |> as.data.frame() |> rowSums(na.rm = TRUE), by = list(municipality, q)]

# impute forward
decay = c(0.15, 0.25, 0.6, NA)
impgridq[imputeblock_fwd == TRUE, income_extrapolated := exp(predict(lm(log(V1) ~ year, weights = decay, data = .SD), newdata = .SD)), by = list(municipality, q)]
impgridq[is.na(V1) & is.na(income_interpolated) & imputeblock_fwd == TRUE, source := "extrapolated forwards"]

# impute backward
impgridq[imputeblock_bck == TRUE, income_extrapolated := exp(predict(lm(log(V1) ~ year, weights = rev(decay), data = .SD), newdata = .SD)), by = list(municipality, q)]
impgridq[is.na(V1) & is.na(income_interpolated) & imputeblock_bck == TRUE, source := "extrapolated backwards"]

# impute backward 2
decay = c(0.15, 0.25, 0.6, NA, NA)
impgridq[imputeblock_bck2 == TRUE & municipality == "Nijmegen" & q == 0.5]
impgridq[imputeblock_bck2 == TRUE, income_extrapolated2 := exp(predict(lm(log(V1) ~ year, weights = rev(decay), data = .SD), newdata = .SD)), by = list(municipality, q)]
impgridq[is.na(V1) & is.na(income_interpolated) & imputeblock_bck2 == TRUE, source := "extrapolated backwards double"]

impgridq[is.na(source), source := "not imputed"]
impgridq[, .N, by = source]

impgridq[, income_iep := fcase(
    !is.na(V1), V1,
    !is.na(income_interpolated), income_interpolated,
    !is.na(income_extrapolated), income_extrapolated,
    !is.na(income_extrapolated2), income_extrapolated2,
    default = NA
)]

impgridq[q == 1 & !is.na(income_iep), as.list(summary(income_iep)), by = source]

# TODO: now you only do income_predicted_cbn_1900, better to do
# income_predicted_cbn, and apply the deflator afterwards, and maybe even do
# this for each income measure

# use inter/extrapolated percentiles to create
set.seed(123)
year_mun_ids = impgridq[is.na(V1) & !is.na(income_iep), unique(year_mun_id)]
imputelist = list()
for (ymi in year_mun_ids){
    n = impgrid[year_mun_id == ymi, households]
    qs = impgridq[year_mun_id == ymi, income_iep]
    lqs = log(qs)
    u = runif(n)
    synth = approx(x = probs, y = lqs, xout = u)$y
    dat = data.table(
        income_predicted_cbn_1900 = exp(synth),
        year_mun_id = ymi,
        refpop = n,
        amco = impgrid[year_mun_id == ymi, amco],
        year = impgrid[year_mun_id == ymi, year],
        imputed = TRUE
    )
    imputelist[[ymi]] = dat
}

synth_munics = rbindlist(imputelist)
synth_munics[, .N, by = year_mun_id]
plt(~log(income_predicted_cbn_1900), data = synth_munics, type = "hist")

txi = rbindlist(list(txi, synth_munics), fill = TRUE)

txi[, fully_imputed := all(imputed), by = year_mun_id]
txi[, municipality := na.omit(municipality)[1], by = amco]
txi[, province := na.omit(province)[1], by = amco]
txi[, dec := na.omit(dec)[1], by = year]
# x[municipality == "Utrecht", .N,  by = list(year, dec, province, amco, municipality, year_mun_id, fully_imputed)]

pdf("./fig/ineq_v631_ipol.pdf", height = 6)
mypar()
txi[dec > 1860, ineq::Gini(income_predicted_xgb), by = dec] |> plot(ylim = c(0.35, 0.75), type = "b")
txi[dec > 1860, ineq::Gini(income_predicted_lin), by = dec] |> points(, type = "b", col = 2)
txi[dec > 1860, ineq::Gini(income_predicted_cbn), by = dec] |> points(, type = "b", col = 3)
txi[dec > 1860 & imputed == FALSE, ineq::Gini(income_predicted_xgb), by = dec] |> points(col = 4, type = "b")
txi[dec > 1860 & imputed == FALSE, ineq::Gini(income_predicted_lin), by = dec] |> points(ylim = c(0.4, 0.75), type = "b", col = 5)
txi[dec > 1860 & imputed == FALSE, ineq::Gini(income_predicted_cbn), by = dec] |> points(ylim = c(0.4, 0.75), type = "b", col = 6)
legend("toprigh", fill = 1:6, 
    legend = c(
        "w imps, xgb",
        "w imps, lin",
        "w imps, cbn",
        "w/o imps, xgb",
        "w/o imps, lin",
        "w/o imps, cbn"
    )
)
dev.off()

# incomplete list but covers 80% of occupations
agri_occs = c("landbouwer", "veehouder", "landman", "veldarbeider", "landbouwster", "tuinder",
    "melkboer", "bouw", "bouwvrouw", "bouwman",
    "visscher", "visser", "vissersknecht",
    "herder", "melkboer",
    "bloemkweeker", "tuinman", "landb.", "tuinier", "eendenhouder", "boerin", "boer", "koemelker",
    "tuinknecht", "koehouder", "schaapherder", "veehoudersche", "veehoudster", "tuinster",
    "landbouwersknecht", "boerenarbeider", "stalknecht", "veehouderes", "herborist"
)

# NB: occups "" and "imputed" are now FALSE
txi[, agricultural_occ := tolower(trimws(occupation)) %in% agri_occs]

# export munic-level
out = txi[, list(
        gini_predicted_xgb = ineq::Gini(income_predicted_xgb),
        theil_predicted_xgb = ineq::Theil(income_predicted_xgb),
        mean_predicted_xgb = mean(income_predicted_xgb, na.rm = TRUE),
        sd_predicted_xgb = sd(income_predicted_xgb, na.rm = TRUE),
        min_predicted_xgb = min(income_predicted_xgb, na.rm = TRUE),
        max_predicted_xgb = max(income_predicted_xgb, na.rm = TRUE),
        q99_predicted_xgb = quantile(income_predicted_xgb, 0.99, na.rm = TRUE),
        q90_predicted_xgb = quantile(income_predicted_xgb, 0.9, na.rm = TRUE),
        q80_predicted_xgb = quantile(income_predicted_xgb, 0.8, na.rm = TRUE),
        q50_predicted_xgb = quantile(income_predicted_xgb, 0.5, na.rm = TRUE),
        q20_predicted_xgb = quantile(income_predicted_xgb, 0.2, na.rm = TRUE),
        q10_predicted_xgb = quantile(income_predicted_xgb, 0.1, na.rm = TRUE),
        top50_share_xgb = top_income_share(income_predicted_xgb, 0.5),
        top20_share_xgb = top_income_share(income_predicted_xgb, 0.2),
        top10_share_xgb = top_income_share(income_predicted_xgb, 0.1),
        top1_share_xgb = top_income_share(income_predicted_xgb, 0.01),

        gini_predicted_xgb_1900 = ineq::Gini(income_predicted_xgb_1900),
        theil_predicted_xgb_1900 = ineq::Theil(income_predicted_xgb_1900),
        mean_predicted_xgb_1900 = mean(income_predicted_xgb_1900, na.rm = TRUE),
        sd_predicted_xgb_1900 = sd(income_predicted_xgb_1900, na.rm = TRUE),
        min_predicted_xgb_1900 = min(income_predicted_xgb_1900, na.rm = TRUE),
        max_predicted_xgb_1900 = max(income_predicted_xgb_1900, na.rm = TRUE),
        q99_predicted_xgb_1900 = quantile(income_predicted_xgb_1900, 0.99, na.rm = TRUE),
        q90_predicted_xgb_1900 = quantile(income_predicted_xgb_1900, 0.9, na.rm = TRUE),
        q80_predicted_xgb_1900 = quantile(income_predicted_xgb_1900, 0.8, na.rm = TRUE),
        q50_predicted_xgb_1900 = quantile(income_predicted_xgb_1900, 0.5, na.rm = TRUE),
        q20_predicted_xgb_1900 = quantile(income_predicted_xgb_1900, 0.2, na.rm = TRUE),
        q10_predicted_xgb_1900 = quantile(income_predicted_xgb_1900, 0.1, na.rm = TRUE),
        top50_share_xgb_1900 = top_income_share(income_predicted_xgb_1900, 0.5),
        top20_share_xgb_1900 = top_income_share(income_predicted_xgb_1900, 0.2),
        top10_share_xgb_1900 = top_income_share(income_predicted_xgb_1900, 0.1),
        top1_share_xgb_1900 = top_income_share(income_predicted_xgb_1900, 0.01),

        gini_predicted_lin = ineq::Gini(income_predicted_lin),
        theil_predicted_lin = ineq::Theil(income_predicted_lin),
        mean_predicted_lin = mean(income_predicted_lin, na.rm = TRUE),
        sd_predicted_lin = sd(income_predicted_lin, na.rm = TRUE),
        min_predicted_lin = min(income_predicted_lin, na.rm = TRUE),
        max_predicted_lin = max(income_predicted_lin, na.rm = TRUE),
        q99_predicted_lin = quantile(income_predicted_lin, 0.99, na.rm = TRUE),
        q90_predicted_lin = quantile(income_predicted_lin, 0.9, na.rm = TRUE),
        q80_predicted_lin = quantile(income_predicted_lin, 0.8, na.rm = TRUE),
        q50_predicted_lin = quantile(income_predicted_lin, 0.5, na.rm = TRUE),
        q20_predicted_lin = quantile(income_predicted_lin, 0.2, na.rm = TRUE),
        q10_predicted_lin = quantile(income_predicted_lin, 0.1, na.rm = TRUE),
        top50_share_lin = top_income_share(income_predicted_lin, 0.5),
        top20_share_lin = top_income_share(income_predicted_lin, 0.2),
        top10_share_lin = top_income_share(income_predicted_lin, 0.1),
        top1_share_lin = top_income_share(income_predicted_lin, 0.01),

        gini_predicted_lin_1900 = ineq::Gini(income_predicted_lin_1900),
        theil_predicted_lin_1900 = ineq::Theil(income_predicted_lin_1900),
        mean_predicted_lin_1900 = mean(income_predicted_lin_1900, na.rm = TRUE),
        sd_predicted_lin_1900 = sd(income_predicted_lin_1900, na.rm = TRUE),
        min_predicted_lin_1900 = min(income_predicted_lin_1900, na.rm = TRUE),
        max_predicted_lin_1900 = max(income_predicted_lin_1900, na.rm = TRUE),
        q99_predicted_lin_1900 = quantile(income_predicted_lin_1900, 0.99, na.rm = TRUE),
        q90_predicted_lin_1900 = quantile(income_predicted_lin_1900, 0.9, na.rm = TRUE),
        q80_predicted_lin_1900 = quantile(income_predicted_lin_1900, 0.8, na.rm = TRUE),
        q50_predicted_lin_1900 = quantile(income_predicted_lin_1900, 0.5, na.rm = TRUE),
        q20_predicted_lin_1900 = quantile(income_predicted_lin_1900, 0.2, na.rm = TRUE),
        q10_predicted_lin_1900 = quantile(income_predicted_lin_1900, 0.1, na.rm = TRUE),
        top50_share_lin_1900 = top_income_share(income_predicted_lin_1900, 0.5),
        top20_share_lin_1900 = top_income_share(income_predicted_lin_1900, 0.2),
        top10_share_lin_1900 = top_income_share(income_predicted_lin_1900, 0.1),
        top1_share_lin_1900 = top_income_share(income_predicted_lin_1900, 0.01),

        gini_predicted_cbn = ineq::Gini(income_predicted_cbn),
        theil_predicted_cbn = ineq::Theil(income_predicted_cbn),
        mean_predicted_cbn = mean(income_predicted_cbn, na.rm = TRUE),
        sd_predicted_cbn = sd(income_predicted_cbn, na.rm = TRUE),
        min_predicted_cbn = min(income_predicted_cbn, na.rm = TRUE),
        max_predicted_cbn = max(income_predicted_cbn, na.rm = TRUE),
        q99_predicted_cbn = quantile(income_predicted_cbn, 0.99, na.rm = TRUE),
        q90_predicted_cbn = quantile(income_predicted_cbn, 0.9, na.rm = TRUE),
        q80_predicted_cbn = quantile(income_predicted_cbn, 0.8, na.rm = TRUE),
        q50_predicted_cbn = quantile(income_predicted_cbn, 0.5, na.rm = TRUE),
        q20_predicted_cbn = quantile(income_predicted_cbn, 0.2, na.rm = TRUE),
        q10_predicted_cbn = quantile(income_predicted_cbn, 0.1, na.rm = TRUE),
        top50_share_cbn = top_income_share(income_predicted_cbn, 0.5),
        top20_share_cbn = top_income_share(income_predicted_cbn, 0.2),
        top10_share_cbn = top_income_share(income_predicted_cbn, 0.1),
        top1_share_cbn = top_income_share(income_predicted_cbn, 0.01),

        gini_predicted_cbn_1900 = ineq::Gini(income_predicted_cbn_1900),
        theil_predicted_cbn_1900 = ineq::Theil(income_predicted_cbn_1900),
        mean_predicted_cbn_1900 = mean(income_predicted_cbn_1900, na.rm = TRUE),
        sd_predicted_cbn_1900 = sd(income_predicted_cbn_1900, na.rm = TRUE),
        min_predicted_cbn_1900 = min(income_predicted_cbn_1900, na.rm = TRUE),
        max_predicted_cbn_1900 = max(income_predicted_cbn_1900, na.rm = TRUE),
        q99_predicted_cbn_1900 = quantile(income_predicted_cbn_1900, 0.99, na.rm = TRUE),
        q90_predicted_cbn_1900 = quantile(income_predicted_cbn_1900, 0.9, na.rm = TRUE),
        q80_predicted_cbn_1900 = quantile(income_predicted_cbn_1900, 0.8, na.rm = TRUE),
        q50_predicted_cbn_1900 = quantile(income_predicted_cbn_1900, 0.5, na.rm = TRUE),
        q20_predicted_cbn_1900 = quantile(income_predicted_cbn_1900, 0.2, na.rm = TRUE),
        q10_predicted_cbn_1900 = quantile(income_predicted_cbn_1900, 0.1, na.rm = TRUE),
        top50_share_cbn_1900 = top_income_share(income_predicted_cbn_1900, 0.5),
        top20_share_cbn_1900 = top_income_share(income_predicted_cbn_1900, 0.2),
        top10_share_cbn_1900 = top_income_share(income_predicted_cbn_1900, 0.1),
        top1_share_cbn_1900 = top_income_share(income_predicted_cbn_1900, 0.01),

        refpop = unique(refpop),
        share_imputed = mean(imputed),
        nhh_imputed = sum(imputed),
        nhh_not_imputed = sum(!imputed),
        n_with_occs = sum(occupation != "" & occupation != "imputed" & !is.na(occupation)),
        n_agricultural_occ = sum(agricultural_occ == TRUE, na.rm = TRUE),
        nhh = .N
    ),
    by = list(year, dec, province, amco, municipality, year_mun_id, fully_imputed)
]
out = out[, lapply(.SD, \(x) ifelse(is.infinite(x), NA, x))]

# if no occs, n_agri_occ == 0 is artifact of na.rm, fix
out[n_with_occs == 0, n_agricultural_occ := NA]
out[!is.na(n_agricultural_occ), list(year_mun_id, n_with_occs, nhh_not_imputed, nhh_imputed, refpop, n_agricultural_occ)] |> print(200)

nrow(out)
out = merge(out, hdng, by = c("amco", "year"))
nrow(out)
out[is.na(pop_31_12)]

# occ counts etc.
occs = fread("~/repos/hipnl/dat/hdng_occs.csv")
occ09 = fread("~/repos/hipnl/dat/sectors1909_redistributed.csv")
occ_bbin = fread("~/repos/hipnl/dat/primary_share_imputations_beta_binomial.csv")
occ_zibb = fread("~/repos/hipnl/dat/primary_share_imputations_dispersed_zibb.csv")

occs = rbind(occs, occ09[, 
    list(amco = amco, year = 1909, dec = 1910, 
        primary = primary_dst, 
        secondary = secondary_dst, 
        tertiary = tertiary_dst, 
        other_occupations)], 
    fill = TRUE)
setorder(occs, amco, year)

# sub with harmonised occ counts

occs[dec == 1930, dec := 1920]


occ_tomerge = merge(
    occ_bbin,
    occ_zibb[, list(amco, dec, pred_primary, pred_share_primary)],
    by = c("amco", "dec"),
    suffixes = c("_bbin", "_zibb")
)
setnames(occ_tomerge, "source", "source_primary_share")

out = merge(
    out, 
    occ_tomerge[, -"municipality"], 
    by = c("amco", "dec"), 
    all.x = TRUE, 
    suffixes = c("", "census_cc")
)

out = out[year_mun_id != "1899_Zuidwolde"] # better income estimates (clear deductions)
out = out[year_mun_id != "1920_Wilnis"]    # fewer imputations, though toss-up 1919/1920
out = out[year_mun_id != "1869_Bunnik"]    # has missing observation that's a problem in some contexts

fwrite(out, 
    file = "~/repos/hipnl/dat/hipnl_ineq_munic_631_2.1_new_primshares.csv" # moves removed and households aggregated
    # file = "~/repos/hipnl/dat/hipnl_ineq_munic_631_2.0_moves_households.csv" # moves removed and households aggregated
    # file = "~/repos/hipnl/dat/hipnl_ineq_munic_631_1.14_agri.csv" # fixes agri
    # file = "~/repos/hipnl/dat/hipnl_ineq_munic_631_1.13_refpop_full.csv" # occups, refpops, imputation lower bound
    # file = "~/repos/hipnl/dat/hipnl_ineq_munic_631_1.12_maskedtaxes.csv" # occups, refpops, imputation lower bound
    # file = "~/repos/hipnl/dat/hipnl_ineq_munic_631_1.11_1870imps.csv" # occups, refpops, imputation lower bound
    # file = "~/repos/hipnl/dat/hipnl_ineq_munic_631_1.10.csv" # occups, refpops, imputation lower bound
    # file = "~/repos/hipnl/dat/hipnl_ineq_munic_631_1.7.csv" # occups, refpops, imputation lower bound
    # file = "~/repos/hipnl/dat/hipnl_ineq_munic_631_1.6.csv" # occups, refpops, imputation lower bound
    # file = "~/repos/hipnl/dat/hipnl_ineq_munic_631_1.5.csv" # occups, refpops, imputation lower bound
    # file = "~/repos/hipnl/dat/hipnl_ineq_munic_631_1.4.csv" # occups, refpops, imputation lower bound
    # file = "~/repos/hipnl/dat/hipnl_ineq_munic_631_1.2.csv"
    # file = "~/repos/hipnl/dat/hipnl_ineq_munic_6_3_1.csv"
)


# broken returns in data, ocr artefact
charcols = sapply(txi, class) == "character"
charcols = names(txi)[charcols]
txi[, surname := stringi::stri_replace_all_fixed(surname, "\n", " ")]
txi[, (charcols) := lapply(.SD, stringi::stri_replace_all_regex, "\\R", " "), .SDcols = charcols]
txi[, (charcols) := lapply(.SD, stringi::stri_replace_all_fixed, "_x000D_", " "), .SDcols = charcols]

# seemingly no utf8 problems, but stata complained anyway
txi[, lapply(.SD, \(column) sum(!stringi::stri_enc_isutf8(na.omit(column)))), .SDcols = charcols] |>
    t() |> sum()

# write out occs to use it for sector shares

# occ_out = x[, list(
#         pop_hdng = unique(pop_31_12),
#         refpop = unique(refpop),
#         share_imputed = mean(imputed),
#         nhh_imputed = sum(imputed),
#         nhh_not_imputed = sum(!imputed),
#         n_with_occs = sum(occupation != ""),
#         primary = sum(agricultural_occ),
#         nhh = .N
#     ),
#     by = list(dec, municipality, amco, year_mun_id)
# ]
# occ_out[order(primary)]
# occ_out[]
# use out to make synthetic observations for relevant munics
dim(txi)
txi = merge(
    txi,
    occ_tomerge[, -"municipality"],
    by = c("amco", "dec"),
    all.x = TRUE, all.y = FALSE
)
dim(txi)
fwrite(
    x = txi, 
    file = "~/repos/hipnl/dat/hipnl_imputed_631_2.1_new_primshares.csv.gz", # moves removed and households aggregated
    # file = "~/repos/hipnl/dat/hipnl_imputed_631_2.0_moves_households.csv", # moves removed and households aggregated
    # file = "~/repos/hipnl/dat/hipnl_imputed_631_1.14_agri.csv", # agri occs fixes
    # file = "~/repos/hipnl/dat/hipnl_imputed_631_1.13_refpop_full.csv",
    # file = "~/repos/hipnl/dat/hipnl_imputed_631_1.12_maskedtaxesa_full.csv.gz",
    # file = "~/repos/hipnl/dat/hipnl_imputed_631_1.11_1870imps_full.csv.gz"),
    # file = "~/repos/hipnl/dat/hipnl_imputed_631_1.11_agri.csv",
    encoding = "UTF-8", 
    bom = TRUE
)

txi[!is.na(income_predicted_cbn_1900), ineq::Gini(income_predicted_cbn_1900), by = year_mun_id]

plt(~log(income_predicted_cbn_1900) | dec, data = txi[between(dec, 1890, 1910)], type = "density", bw = 0.15)

totab = txi[income_predicted_cbn < 1000 & between(dec, 1900, 1920), .N, by = list(province, dec, inc = round(income_predicted_cbn, -2))] |> dcast(dec + province ~ inc)
totab[order(province, dec)]

txi[dec == 1910, .N, by = list(income_predicted_cbn, income_predicted_cbn_1900)][order(-N)][1:20]
txi[dec == 1910 & income_predicted_cbn == 650, .N, by = municipality][order(N)]
txi[dec == 1910, .N, by = municipality][order(N)]
txi[year_mun_id == "1909_Utrecht", .N, by = income_predicted_cbn][order(N)]

txi[, list(mean = mean(income_predicted_cbn_1900), median = median(income_predicted_cbn_1900)), by = dec] |>
    knitr::kable(digits = 0)

out_wh = txi[municipality %in% c("Waalwijk", "Hilvarenbeek"),
    list(year, municipality, year_mun_id, amco, 
        record_guid, record_address_guid,
        volgnummer, wijk, street, house_nr_street,
        initials, title, firstnames, tussenvoegsel, surname, suffix,
        female, maritalstatus, n_children, occupation,
        class, income_gross, income_taxable, deductions, tax,
        income_predicted_cbn, imputed,
        file_name, sheet_name)]
out_wh = out_wh[year_mun_id != "1859_Hilvarenbeek"]
fwrite(
    out_wh, 
    file =  "~/repos/hipnl/dat/hipnl_6.3.1_wwhvb.csv")

# fwrite(x, "~/repos/hipnl/dat/hipnl_imputed_631_1.7.csv")
# fwrite(x, "~/repos/hipnl/dat/hipnl_imputed_6_3_1.csv.gz")


# fwrite(x, "~/repos/hipnl/dat/hipnl_imputed_631_1.7.2_linefix_full.csv.gz")

x2 = fread("/Users/Rijpm101/repos/hipnl/dat/hipnl_imputed_631_1.7.csv")
head(x2)
x2$surname[199083:199085]
txi$surname[199083:199085]




toplot = x[dec > 1850, list(mean(income_predicted_1900), mean(income_predicted_lin_1900)), by = dec]
par(mfrow = c(1,1))
matplot(toplot[, -1], type = "l")
toplot = x[, list(median(income_predicted_1900), median(income_predicted_lin_1900)), by = dec]
matplot(toplot[, -1], type = "l")
x[, quantile(income_predicted_1900)]


toplot = x[imputed == FALSE, qnt(income_predicted_1900, probs = 1:9/10), by = dec]
plt(out ~ dec | rn, data = toplot, type = "b")
grid()
toplot = x[, qnt(income_predicted, probs = 1:9/10), by = dec]
plt(out ~ dec | rn, data = toplot, type = "b")

plt(income_predicted_1900 ~ dec, data = x, type = "boxplot", log = "y")

toplot = x[, list(rbind(quantile(income_predicted_1900)), rbind(quantile(income_predicted_lin_1900))), by = dec]
matplot(toplot[, -1], type = "l")

# 1879_Doniawerstal # no imps
# 1919_Loenen # no imps
# 1919_Harlingen # first two vry low
# 1870_Rauwerderhem
# 1920_Hattem
tax[, min(income_predicted), by = year_mun_id][order(V1)]
tax[, quantile(income_predicted, 0.01), by = year_mun_id][order(V1)]
tax[, quantile(income_predicted, 0.1), by = year_mun_id][order(V1)]

tax[year_mun_id == "1870_Rauwerderhem"][order(income_predicted), list(income_predicted)]
tax[year_mun_id == "1870_Rauwerderhem"][order(income_predicted), list(income_predicted)][1:20]
x[year_mun_id == "1870_Rauwerderhem"][order(income_predicted), list(imputed, income_predicted)]
x[year_mun_id == "1870_Rauwerderhem"][order(income_predicted), list(imputed, income_predicted)][1:300] |> as.data.frame()
# trim first two?

toplot = tax[, list(min(income_predicted), quantile(income_predicted, 0.01)), by = year_mun_id]
toplot = tax[order(income_predicted), list(min(income_predicted), quantile(income_predicted, 0.01)), by = year_mun_id]
toplot = tax[order(income_predicted), list(min(income_predicted), income_predicted[1]), by = year_mun_id]
plot(V2 ~ V1, data = toplot)
abline(v = c(100, 200), h = 200)
curve(1*x, add = TRUE)

toplot = tax[order(income_predicted), 
    list(
        rep(min(income_predicted), 10), 
        head(income_predicted, 10)), 
    by = year_mun_id]
plt(V2 ~ V1 | year_mun_id, data = toplot, legend = FALSE, type = "l")
tax[income_gross < 200]
tax[, list(.N, sum(income_predicted < 200)), by = year_mun_id][order(-V2)][1:15]


# out[!is.na(tertiary) & dec > 1880, list(pop_31_12, dec)][order(dec)]

out[, uniqueN(year), by = list(municipality, dec)][order(V1)]

# notice the pop = 0, these come from the HDNG and need to be fixed

# m = lm(log(refpop) ~ log(pop_31_12), data = out)
# out[, refpop_predicted := exp(predict(m, newdata = .SD))]
# out[, refpop_resid := refpop_predicted - refpop]
# out[, pct_dev := abs(refpop_resid) / refpop]
# out[order(abs(refpop_resid)), list(year, municipality, pop_31_12, refpop, refpop_predicted, refpop_resid)]
# out[order(-abs(pct_dev)), list(year, municipality, pop_31_12, refpop, refpop_predicted, refpop_resid, pct_dev)]
# plt(refpop ~ pop_31_12 | municipality, data = out[order(pop_31_12)], log = "xy", legend = FALSE, type = "b")

# out[municipality == "Eindhoven", list(year,pop_31_12, refpop, refpop_predicted, pct_dev)]
# out[municipality == "Borger", list(year,pop_31_12, refpop, refpop_predicted, pct_dev)]
# out[municipality == "Borger", list(year,pop_31_12, refpop, nhh_not_imputed, refpop / pop_31_12)]

# out[municipality == "Nijmegen", .SD, .SDcols = patterns("year|nhh|refpop|pop")]

tax[year_mun_id == "1879_Vlieland", list(income_predicted, tax)]
tax[year_mun_id == "1879_Vlieland", list(income_predicted_lin, tax)]
out[municipality == "Vlieland", .SD, .SDcols = patterns("_xgb$|dec|nhh")]
x[year_mun_id == "1879_Vlieland", list(income_predicted, income_predicted_xgb, income_predicted_lin), imputed]
x[year_mun_id == "1879_Vlieland", sum(income_predicted[income_predicted > quantile(income_predicted, 0.5)])]
x[year_mun_id == "1879_Vlieland", sum(income_predicted[income_predicted > quantile(income_predicted, 0.5)]) / sum(income_predicted)]

x[year_mun_id == "1879_Vlieland", list(sum(income_predicted), sum(income_predicted[income_predicted > quantile(income_predicted, 0.5)]))]
x[year_mun_id == "1879_Vlieland", list(sum(income_predicted), sum(income_predicted[income_predicted >= quantile(income_predicted, 0.5)]))]
out[municipality == "Vlieland", list(dec, q50_predicted_xgb, nhh * mean_predicted_xgb, top50_share_xgb)]
out[municipality == "Vlieland", nhh * mean_predicted_xgb]

x[year_mun_id == "1879_Vlieland", .N, by = income_predicted][order(income_predicted)]


tax[year_mun_id == "1879_Vlieland", .N, by = tax][order(tax)]
tax[year_mun_id == "1879_Vlieland", ineq::Gini(tax)]
tax[year_mun_id == "1879_Vlieland", .N, by = list(tax, income_predicted_xgb)][order(income_predicted_xgb)] |> knitr::kable(digits = 0)
tax[year_mun_id == "1879_Vlieland", ineq::Gini(income_predicted)]
x[year_mun_id == "1879_Vlieland", top_income_share(income_predicted, 0.5)]
x[year_mun_id == "1879_Vlieland", top_income_share2(income_predicted, 0.5)]
x[year_mun_id == "1879_Vlieland", ineq::Gini(income_predicted)]

plt(log(income_gross) ~ log(tax), facet = ~ dec, data = tax[dec > 1850])

x[year_mun_id == "1879_Vlieland", quantile(income_predicted, 0.5, type = 1)]
x[year_mun_id == "1879_Vlieland", quantile(income_predicted, 0.5, type = 2)]
x[year_mun_id == "1879_Vlieland", quantile(income_predicted, 0.5, type = 3)]
x[year_mun_id == "1879_Vlieland", quantile(income_predicted, 0.5, type = 4)]
x[year_mun_id == "1879_Vlieland", quantile(income_predicted, 0.5, type = 5)]
x[year_mun_id == "1879_Vlieland", quantile(income_predicted, 0.5, type = 6)]
x[year_mun_id == "1879_Vlieland", quantile(income_predicted, 0.5, type = 7)]
x[year_mun_id == "1879_Vlieland", quantile(income_predicted, 0.5, type = 8)]
x[year_mun_id == "1879_Vlieland", ecdf(income_predicted)]


plot(income_predicted_lin ~ tax, data = tax[year_mun_id == "1879_Vlieland"], ylim = c(300, 900))
points(income_predicted ~ tax, data = tax[year_mun_id == "1879_Vlieland"], col = 2)


toplot = tax[, 
    list(
        tax = ineq::Gini(tax), 
        xgb = ineq::Gini(income_predicted), 
        lin = ineq::Gini(income_predicted_lin)
    ), 
    by = year_mun_id
]

plot(lin ~ tax, data = toplot, pch = 20, ylim = c(0.05, 0.8))
points(xgb ~ tax, data = toplot, col = 2, pch = 20)
toplot = tax[, list(ineq::Gini(tax), ineq::Gini(income_predicted_lin)), by = year_mun_id]


hdng[year %in% c(186:192 * 10), sum(pop_31_12) / 4.5 / 12, by = year] 
out[, sum(nhh), by = dec]
hdng[year %in% c(186:192 * 10), sum(pop_31_12) / 4.5 / 12, by = year] |> plot(ylim = c(20e3, 150e3))
out[, sum(nhh), by = dec]|> points(col = 2)

# pdf("~/repos/hipnl/img/impviz.pdf")
# for (i in unique(x$year_mun_id)){
#     toplot = x[year_mun_id == i, ]
#     plt(~ log(income_predicted) | imputed, data = toplot, type = "hist", main = i, breaks = 20)
# }
# dev.off()
i = "1909_Leiden"
pdf("~/repos/hipnl/img/leiden1909imps.pdf", height = 6)
toplot = x[year_mun_id == i, ]
mypar()
plt(~ log(income_predicted) | imputed, data = toplot, type = "hist", main = i, breaks = 20)
dev.off()
