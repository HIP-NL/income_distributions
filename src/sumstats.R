library("data.table")

source("./src/functions.R")

txi = fread(file = "~/repos/hipnl/dat/hipnl_imputed_631_2.1_new_primshares.csv.gz")

pop = fread("~/repos/hipnl/dat/hdngpop.csv")

out1 = txi[imputed == FALSE,
    list(
        .N,
        income_gross = sum(!is.na(income_gross)),
        income_taxable = sum(!is.na(income_taxable)),
        tax = sum(!is.na(tax))),
    by = dec]
out2 = txi[imputed == FALSE,
    list(
        .N,
        income_gross = sum(!is.na(income_gross)),
        income_taxable = sum(!is.na(income_taxable) & is.na(income_gross)),
        tax = sum(!is.na(tax) & is.na(income_taxable) & is.na(income_gross))),
    by = dec]
out2[, total := income_gross + income_taxable + tax]

out2[, lapply(.SD, \(x) sum(x) / sum(N))]

knitr::kable(out2, format = "latex", caption = "Observations for preferred income measure by decade", label = "tab:income_sources") |>
    writeLines("./tab/income_sources.tex")

out3 = txi[imputed == FALSE,
    list(
        uniqueN(year_mun_id),
        income_gross = uniqueN(year_mun_id[!is.na(income_gross)]),
        income_taxable = uniqueN(year_mun_id[!is.na(income_taxable) & is.na(income_gross)]),
        tax = uniqueN(year_mun_id[!is.na(tax) & is.na(income_taxable) & is.na(income_gross)])),
    by = dec]
out3[, total := income_gross + income_taxable + tax]

txi[imputed == FALSE, mean(urban), by = dec]

pdf("./fig/urban_bias.pdf", width = 9, height = 8)
mypar(mfrow = c(2,2))
for (i in c(5e3, 10e3, 20e3, 50e3)){
    urban_threshold = i

    urbanisation = pop[, list(share_urban_nld = sum(pop_31_12[pop_31_12 > urban_threshold]) / sum(pop_31_12)), by = year]

    out4 = txi[, list(
        observed_hh = sum(imputed == FALSE),
        reference_hh = .N
        ),
        by = list(amco, year_mun_id, dec)
    ]
    out4 = out4[, list(
        `observed_hh` = sum(observed_hh),
        `reference_hh` = sum(reference_hh),
        `urban_reference_hh` = sum(reference_hh[reference_hh > (urban_threshold / 4.5)])
        ),
        by = dec]
    out4[, share_urban_hipnl := urban_reference_hh / reference_hh]
    out4 = urbanisation[out4, on = c("year" = "dec")]

    # build comparison of bias by threshold
    matplot(out4$year, out4[, list(share_urban_nld, share_urban_hipnl)],
        type = 'b', lty = 1, pch = 20,
        main = paste("Share municipalities > ", as.integer(i)),
        xlab = "year", ylab = "share urban")

    # prep and write table
    setcolorder(out4, "share_urban_nld", after = "share_urban_hipnl")
    setnames(out4, names(out4), gsub("_", " ", names(out4)))
    outpath = paste0("./tab/", "observations_urban", i, ".tex")
    print(outpath)
    knitr::kable(out4, format = "latex", digits = 2,
        caption = "Tax observations, reference population, and share urban, 1860–1920.",
        label = "tab:observations") |>
        writeLines(outpath)
}
legend("topleft", fill = 1:2, legend = c("NLD", "HIPNL"))
dev.off()

# % table: sampled households, reference pops in hh, share urban, share urban nld
# plt(~ log(pop_31_12), facet = ~ year,
#     data = pop[year %in% c(1859, 1869, 1879, 1889, 1899, 1909, 1920) & pop_31_12 > 0],
#     type = "density")
# plt_add(~ log(N), facet = ~ dec,
#     data = txi[dec >= 1860, .N, by = list(year_mun_id, dec)],
#     type = "density")



txi[!is.na(income_predicted_cbn),
    dec_decile := findInterval(income_predicted_cbn, quantile(income_predicted_cbn, 1:9 / 10)),
    by = dec]
toplot = txi[!is.na(income_predicted_cbn), mean(income_predicted_cbn_1900), by = list(dec, dec_decile)][order(dec)]

plt(log(V1) ~ dec | dec_decile, data = toplot, type = "b", pch = 20)
