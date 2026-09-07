# check and fix gross/taxable/tax on a per-municipality basis

# tax[municipality == "Abcoude-Baambrugge" & year == 1863, ..inspvrbs] # no deduc info
# tax[municipality == "Abcoude-Baambrugge" & year == 1869, ..inspvrbs] # no deduc info
# tax[municipality == "Abcoude-Baambrugge" & year == 1879, ..inspvrbs] # no deduc info
# tax[municipality == "Abcoude-Baambrugge" & year == 1889, ..inspvrbs] # no deduc info
# tax[municipality == "Abcoude-Baambrugge" & year == 1899, ..inspvrbs] # no deduc info
# tax[municipality == "Abcoude-Baambrugge" & year == 1909] # gross/taxable available
# tax[municipality == "Abcoude-Baambrugge" & year == 1920, ..inspvrbs] # gross/taxable available

# tax[municipality == "Abcoude-Proosdij" & year == 1872, ..inspvrbs] # no deduc info
# tax[municipality == "Abcoude-Proosdij" & year == 1879, ..inspvrbs] # no deduc info
# tax[municipality == "Abcoude-Proosdij" & year == 1889, ..inspvrbs] # no deduc info
# tax[municipality == "Abcoude-Proosdij" & year == 1899, ..inspvrbs] # no deduc info
# tax[municipality == "Abcoude-Proosdij" & year == 1909, ..inspvrbs] # gross/taxable available
# tax[municipality == "Abcoude-Proosdij" & year == 1920, ..inspvrbs] # gross/taxable available

# tax[municipality == "Alkemade" & year == 1859, ..inspvrbs] # no deduc info
# tax[municipality == "Alkemade" & year == 1868, ..inspvrbs] # no deduc info
# tax[municipality == "Alkemade" & year == 1879, ..inspvrbs] # no deduc info
# tax[municipality == "Alkemade" & year == 1889, ..inspvrbs] # no deduc info
# tax[municipality == "Alkemade" & year == 1899, ..inspvrbs] # no deduc info
# tax[municipality == "Alkemade" & year == 1909, ..inspvrbs] # gross/taxable available
# tax[municipality == "Alkemade" & year == 1919, ..inspvrbs] # gross/taxable available

# tax[municipality == "Amersfoort" & year == 1899, ..inspvrbs] # taxable income, ged. staten archive 1898 show fl. 400 deduc, fl. 500 and below not taxed
tax[municipality == "Amersfoort" & year == 1899, income_gross := income_taxable + 400]
tax[municipality == "Amersfoort" & year == 1909, ..inspvrbs] #  # taxable income, gemeentearchief shows Amersfoort_0002.01_2661 (1897-1907)
tax[year_mun_id == "1909_Amersfoort", 
    income_gross := fcase(
        n_children == 0,           income_taxable + 400,
        between(n_children, 1, 3), income_taxable + 500,
        n_children > 3,            600,
        default = NA
)]
# tax[municipality == "Amersfoort" & year == 1920, ..inspvrbs] # gross/taxable available
tax[year_mun_id == "1920_Amersfoort" & volgnummer == 873, tax := 26.72]
tax[year_mun_id == "1920_Amersfoort" & sheet_name == "data" & volgnummer == 25, tax := 30.08]
tax[year_mun_id == "1920_Amersfoort" & sheet_name == "data" & volgnummer == 882, tax := 40.48]

# tax[municipality == "Beesd" & year == 1870, ..inspvrbs] # no info, not even in scan
# tax[municipality == "Beesd" & year == 1879, ..inspvrbs] # no deduc info
# tax[municipality == "Beesd" & year == 1889, ..inspvrbs] # no deduc info
# tax[municipality == "Beesd" & year == 1899, ..inspvrbs] # income/gross available
# tax[municipality == "Beesd" & year == 1909, ..inspvrbs] # income/gross available
# tax[municipality == "Beesd" & year == 1920, ..inspvrbs] # income/gross available

# tax[municipality == "Bladel en Netersel" & year == 1859, ..inspvrbs] # no info at all
# tax[municipality == "Bladel en Netersel" & year == 1869, ..inspvrbs] # no info at all
# tax[municipality == "Bladel en Netersel" & year == 1879, ..inspvrbs] # no info at all
# tax[municipality == "Bladel en Netersel" & year == 1889, ..inspvrbs] # taxable/gross available, no deduc
# tax[municipality == "Bladel en Netersel" & year == 1899, ..inspvrbs] # taxable/gross available, no deduc
# tax[municipality == "Bladel en Netersel" & year == 1909, ..inspvrbs] # taxable/gross available
# tax[municipality == "Bladel en Netersel" & year == 1920, ..inspvrbs] # taxable/gross available

# tax[municipality == "Brouwershaven" & year == 1859, ..inspvrbs] # very low info scans
# tax[municipality == "Brouwershaven" & year == 1869, ..inspvrbs] # very low info scans
# tax[municipality == "Brouwershaven" & year == 1879, ..inspvrbs] # very low info scans
# tax[municipality == "Brouwershaven" & year == 1889, ..inspvrbs] # taxable/gross available
tax[municipality == "Brouwershaven" & year == 1889, mid := NA]
# tax[municipality == "Brouwershaven" & year == 1899, ..inspvrbs] # taxable/gross available
# tax[municipality == "Brouwershaven" & year == 1909, ..inspvrbs] # taxable/gross available
# tax[municipality == "Brouwershaven" & year == 1920, ..inspvrbs] # taxable/gross available



# tax[municipality == "Eindhoven" & year == 1858, ..inspvrbs] # no deduc info, just taxes
# tax[municipality == "Eindhoven" & year == 1869, ..inspvrbs] # no info at all
tax[municipality == "Eindhoven" & year == 1879, income_taxable := tax * 100] # 1pct tax and 300 deduc
tax[municipality == "Eindhoven" & year == 1879, income_gross := income_taxable + 300] 
# tax[municipality == "Eindhoven" & year == 1889, ..inspvrbs] # taxable and gross, no deduction
# tax[municipality == "Eindhoven" & year == 1899, ..inspvrbs] # taxable and gross, no deduction
tax[municipality == "Eindhoven" & year == 1909, income_raad := income_taxable] # gross_income correct, no deduction, but taxable and raad messed up
tax[municipality == "Eindhoven" & year == 1909, income_taxable := income_gross - 300] # gross_income correct, no deduction, but taxable and raad messed up
# tax[municipality == "Eindhoven" & year == 1917, ..inspvrbs] # taxable and gross, deductions correct

# tax[municipality == "Geldrop" & year == 1859, ..inspvrbs] # no deduc info
# tax[municipality == "Geldrop" & year == 1869, ..inspvrbs] # no deduc info
# tax[municipality == "Geldrop" & year == 1879, ..inspvrbs] # no deduc info
# tax[municipality == "Geldrop" & year == 1889, ..inspvrbs] # gross and taxable, but gross = "zuiver inkomen", so presuambly quiet deduction
# tax[municipality == "Geldrop" & year == 1899, ..inspvrbs] # gross and taxable, but gross = "zuiver inkomen", so presuambly quiet deduction
# tax[municipality == "Geldrop" & year == 1899, ..inspvrbs] # gross and taxable, but gross = "zuiver inkomen", so presuambly quiet deduction
# tax[municipality == "Geldrop" & year == 1909, ..inspvrbs] # gross and taxable, gross includes proper 250 deduction, still seems low
# tax[municipality == "Geldrop" & year == 1920, ..inspvrbs] # gross and taxable, gross includes proper 500 deduc

# tax[municipality == "Harlingen" & year == 1859, ..inspvrbs] # deduction is on tax, mid seemingly gives gross income
tax[year_mun_id == "1859_Harlingen", income_gross := mid]
tax[year_mun_id == "1859_Harlingen", mid := NA]
# tax[municipality == "Harlingen" & year == 1870, ..inspvrbs] # deduction is on tax, mid seemingly gives gross income
tax[year_mun_id == "1870_Harlingen", income_gross := mid]
tax[year_mun_id == "1870_Harlingen", mid := NA]
# tax[municipality == "Harlingen" & year == 1881, ..inspvrbs] # gross and taxable, garbage tax
# tax[municipality == "Harlingen" & year == 1889, ..inspvrbs] # gross and taxable can be reconstructed
tax[municipality == "Harlingen" & year == 1889, income_taxable := income_gross - 300 - deductions] # gross and taxable can be reconstructed
# tax[municipality == "Harlingen" & year == 1909, ..inspvrbs] # gross and taxable
# tax[municipality == "Harlingen" & year == 1919, ..inspvrbs] # gross and taxable

# tax[municipality == "Hattem" & year == 1909, ..inspvrbs] # gross and taxable but gross feels a bit low
# tax[municipality == "Hattem" & year == 1920, ..inspvrbs] # gross and taxable capture deduction of 700 + 75 per kid + other variants

# tax[municipality == "Helvoirt" & year == 1859, ..inspvrbs] # no info
# tax[municipality == "Helvoirt" & year == 1869, ..inspvrbs] # no info
# tax[municipality == "Helvoirt" & year == 1879, ..inspvrbs] # kid deduction, but at tax level and not recorded
# tax[municipality == "Helvoirt" & year == 1889, ..inspvrbs] # gross and taxable, gross still seems low, zuiver inkomen mentioned, deduc system unclear
tax[municipality == "Helvoirt" & year == 1899, income_gross := income_taxable + 200] # only taxable, 200 deduction mentioned in metadata, but not on scan, but seems plausible (though still somewhat low)
# 1909 missing for no clear reason
# tax[municipality == "Helvoirt" & year == 1920, ..inspvrbs] # gross and taxable, works

# tax[municipality == "Hilvarenbeek" & year == 1869, ..inspvrbs] # no deduc info at all
# tax[municipality == "Hilvarenbeek" & year == 1879, ..inspvrbs] # no deduc info at all
# tax[municipality == "Hilvarenbeek" & year == 1890, ..inspvrbs] # taxable and gross reflect deductions
# tax[municipality == "Hilvarenbeek" & year == 1899, ..inspvrbs] # taxable and gross reflect deductions
# tax[municipality == "Hilvarenbeek" & year == 1909, ..inspvrbs] # taxable and gross reflect deductions
# tax[municipality == "Hilvarenbeek" & year == 1920, ..inspvrbs] # taxable and gross reflect deductions

# tax[municipality == "Hindeloopen" & year == 1869, ..inspvrbs] # taxable and gross reflect deductions
# tax[municipality == "Hindeloopen" & year == 1879, ..inspvrbs] # taxable and gross reflect deductions

# tax[municipality == "Hulst" & year == 1859, ..inspvrbs] # no deduc info, just taxes
# tax[municipality == "Hulst" & year == 1869, ..inspvrbs] # no deduc info, just taxes
# tax[municipality == "Hulst" & year == 1879, ..inspvrbs] # no info, mid seems low
tax[municipality == "Hulst" & year == 1899, income_gross := income_taxable] # no info, seems like gross?
tax[municipality == "Hulst" & year == 1899, income_taxable := NA] # no info, seems like gross?
tax[municipality == "Hulst" & year == 1909, income_gross := income_taxable] # no info, seems like gross?
tax[municipality == "Hulst" & year == 1909, income_taxable := NA] # no info, seems like gross?
tax[municipality == "Hulst" & year == 1917, income_gross := income_taxable] # no info, seems like gross?
tax[municipality == "Hulst" & year == 1917, income_taxable := NA] # no info, seems like gross?

# tax[municipality == "Landsmeer" & year == 1911, ..inspvrbs] # gross and taxable line up with deduc rule
# tax[municipality == "Landsmeer" & year == 1921, ..inspvrbs] # gross and taxable line up with deduc rule

# tax[municipality == "Leende" & year == 1859, ..inspvrbs] # no deduc info
# tax[municipality == "Leende" & year == 1870, ..inspvrbs] # no deduc info
# tax[municipality == "Leende" & year == 1879, ..inspvrbs] # no deduc info
# tax[municipality == "Leende" & year == 1889, ..inspvrbs] # gross and taxable line up with deduc rule, few odd rows though. nb income_raad is income_raad_taxable, so don't overwrite gross. Ideally you add income_raad_gross as well.
# tax[municipality == "Leende" & year == 1899, ..inspvrbs] # gross and taxable line up with deduc rule. No raad corrections, though presumably taxable
# tax[municipality == "Leende" & year == 1909, ..inspvrbs] # gross and taxable line up with deduc rule, few odd rows though
tax[municipality == "Leende" & year == 1909, income_gross := income_taxable + deductions] # taxable and deductions, add up
# tax[municipality == "Leende" & year == 1920, ..inspvrbs] # taxable and deductions, add up
tax[municipality == "Leende" & year == 1920, income_gross := income_taxable + deductions] # taxable and deductions, add up

# this was a bigger problem but now just two weird values for income_taxable
# tax[year_mun_id == "1879_Leiden", ..inspvrbs][order(income_gross)] # taxable/gross, looks good
# tax[year_mun_id == "1889_Leiden", ..inspvrbs]
problems = tax[municipality == "Leiden" & year == 1889 & tax > income_taxable, volgnummer]
tax[municipality == "Leiden" & year == 1889 & volgnummer %in% problems, income_taxable := NA]
tax[municipality == "Leiden" & year == 1889 & volgnummer %in% problems, income_taxable := NA]
# tax[year_mun_id == "1899_Leiden", ..inspvrbs][order(income_gross)] # gross only, looks good
# tax[year_mun_id == "1919_Leiden", ..inspvrbs][order(income_gross)] # income_gross, two low numbers here are correct
# tax[year_mun_id == "1909_Leiden", ..inspvrbs][order(mid)] # indeed mid and income gross, messy but ok
tax[year_mun_id == "1909_Leiden" & is.na(income_gross), income_gross := mid]  # indeed mid and income gross, messy but ok

# tax[municipality == "Lochem" & year == 1869, ..inspvrbs] # no deduc info
# tax[municipality == "Lochem" & year == 1890, ..inspvrbs] # no deduc info
# tax[municipality == "Lochem" & year == 1899, ..inspvrbs] # no deduc info
# tax[municipality == "Lochem" & year == 1910, ..inspvrbs] # no deduc info
# tax[municipality == "Lochem" & year == 1920, ..inspvrbs] # no deduc info

# tax[municipality == "Loenen" & year == 1859, ..inspvrbs] # no deduc info, just taxes
# tax[municipality == "Loenen" & year == 1869, ..inspvrbs] # no deduc info, just taxes
tax[municipality == "Loenen" & year == 1879, ..inspvrbs][order(income_taxable)] # taxable only, but maybe this is actually gross
tax[municipality == "Loenen" & year == 1913, ..inspvrbs][order(income_taxable)] # taxable only, now it does look like taxable proper
# tax[municipality == "Loenen" & year == 1919, ..inspvrbs][order(income_gross)] # gross/taxable reflects deduction
tax[municipality == "Loenen" & year == 1919, c("income_gross", "income_taxable") := list(income_taxable, income_gross)] # gross/taxable reflects deduction

# tax[municipality == "Maarheeze" & year == 1860, ..inspvrbs] # no deduc info
# tax[municipality == "Maarheeze" & year == 1869, ..inspvrbs] # no deduc info
# tax[municipality == "Maarheeze" & year == 1879, ..inspvrbs] # no deduc info
# tax[municipality == "Maarheeze" & year == 1889, ..inspvrbs] # gross/tax seemingly reflects no deductions
# tax[municipality == "Maarheeze" & year == 1899, ..inspvrbs] # gross/tax seemingly reflects no deductions
# tax[municipality == "Maarheeze" & year == 1909, ..inspvrbs] # gross/tax reflects deductions, seems low
# tax[municipality == "Maarheeze" & year == 1920, ..inspvrbs] # gross/tax reflects deductions

# tax[municipality == "Maasniel" & year == 1859, ..inspvrbs] # no deduc info
# tax[municipality == "Maasniel" & year == 1909, ..inspvrbs] # no deduc info, taxable income is indeed that, low
# tax[municipality == "Maasniel" & year == 1920, ..inspvrbs] # no deduc info, taxable income is indeed that, low

# tax[municipality == "Made en Drimmelen" & year == 1858, ..inspvrbs] # no deduc info
# tax[municipality == "Made en Drimmelen" & year == 1869, ..inspvrbs] # no deduc info
# tax[municipality == "Made en Drimmelen" & year == 1879, ..inspvrbs] # reconstruct gross
tax[municipality == "Made en Drimmelen" & year == 1879, income_taxable := tax * 100] # reconstruct gross
tax[municipality == "Made en Drimmelen" & year == 1879, 
    income_gross := fcase(
            income_taxable <= 100,             income_taxable * 1 / (1 - 2/3),
            between(income_taxable, 101, 200), income_taxable * 1 / (1 - 1/2),
            between(income_taxable, 201, 300), income_taxable * 1 / (1 - 2/5),
            between(income_taxable, 301, 400), income_taxable * 1 / (1 - 1/3),
            between(income_taxable, 401, 500), income_taxable * 1 / (1 - 2/7),
            between(income_taxable, 501, 600), income_taxable * 1 / (1 - 1/4),
            income_taxable > 600,              income_taxable * 1 / (1 - 1/9),
            default = NA
    )
]
# tax[municipality == "Made en Drimmelen" & year == 1889, ..inspvrbs] # gross/taxable reflect deduc
# tax[municipality == "Made en Drimmelen" & year == 1899, ..inspvrbs] # gross/taxable reflect deduc
# tax[municipality == "Made en Drimmelen" & year == 1909, ..inspvrbs] # gross/taxable reflect deduc
# tax[municipality == "Made en Drimmelen" & year == 1920, ..inspvrbs] # gross/taxable reflect deduc

# tax[municipality == "Meerlo" & year == 1890, ..inspvrbs] # no deduc info, tax only
# tax[municipality == "Meerlo" & year == 1899, ..inspvrbs] # no deduc info
# tax[municipality == "Meerlo" & year == 1909, ..inspvrbs] # gross/taxable reflect deduc, still seems low
# tax[municipality == "Meerlo" & year == 1920, ..inspvrbs] # gross/taxable reflect deduc, seems plausible

# tax[municipality == "Mijdrecht" & year == 1870, ..inspvrbs] # tax only, no deduc info
# tax[municipality == "Mijdrecht" & year == 1879, ..inspvrbs] # tax only, no deduc info
# tax[municipality == "Mijdrecht" & year == 1889, ..inspvrbs] # tax only, no deduc info
# tax[municipality == "Mijdrecht" & year == 1899, ..inspvrbs] # tax only, no deduc info (dep. staten only from 1916 onwwards)
# tax[municipality == "Mijdrecht" & year == 1919, ..inspvrbs] # gross/taxable, fix zeroes
tax[municipality == "Mijdrecht" & year == 1919 & (income_gross - deductions <= 0), income_taxable := 0] # gross/taxable reflect deduc, seems plausible

# tax[municipality == "Nijmegen" & year == 1889, ..inspvrbs] # mid only, seems to be gross
tax[year_mun_id == "1889_Nijmegen", income_gross := mid]
tax[year_mun_id == "1889_Nijmegen", mid := NA]
# tax[municipality == "Nijmegen" & year == 1899, ..inspvrbs] # tax and gross in schedule, gross = mid
tax[year_mun_id == "1899_Nijmegen", income_gross := mid]
tax[year_mun_id == "1899_Nijmegen", mid := NA]
# tax[municipality == "Nijmegen" & year == 1909, ..inspvrbs] # kid deduc not clear, but mid seems plausible
tax[year_mun_id == "1909_Nijmegen", income_gross := mid]
tax[year_mun_id == "1909_Nijmegen", mid := NA]
# totab = tax[year_mun_id == "1919_Nijmegen", .N, by = list(sheet_name, maritalstatus, children = !is.na(n_children))][order(sheet_name, maritalstatus, children)]
# knitr::kable(totab)
tax[year_mun_id == "1919_Nijmegen" & sheet_name != "data_1", income_gross := fcase(
    maritalstatus == "u", mid + 400,
    maritalstatus == "w", mid + 600,
    maritalstatus == "m", mid + 600,
    default = mid + 400 # arguably 500 as a midpoint but creates diffs between nbs
)]
tax[year_mun_id == "1919_Nijmegen" & sheet_name != "data_1", income_gross := fcase(
    n_children == 1, income_gross + 40,
    n_children > 1, income_gross + n_children * 10,
    default = income_gross # because we don't know
)]
tax[year_mun_id == "1919_Nijmegen" & sheet_name == "data_1", income_gross := mid + 400]
tax[year_mun_id == "1919_Nijmegen", mid := NA]
# tax[year_mun_id == "1919_Nijmegen", summary(income_gross), by = sheet_name]
# the 675 discrepancy will hopefully get fixed once the nijmegen data is updated
# TODO: check status of this

# tax[municipality == "Noordwijk" & year == 1859, ..inspvrbs] # tax only, no deduc info
# tax[municipality == "Noordwijk" & year == 1869, ..inspvrbs] # tax only, no deduc info
# tax[municipality == "Noordwijk" & year == 1879, ..inspvrbs] # tax only, no deduc info
# tax[municipality == "Noordwijk" & year == 1889, ..inspvrbs] # tax only, no deduc info
# tax[municipality == "Noordwijk" & year == 1899, ..inspvrbs] # tax only, no deduc info
# tax[municipality == "Noordwijk" & year == 1909, ..inspvrbs] # gross/taxable reflects deduc
# tax[municipality == "Noordwijk" & year == 1919, ..inspvrbs] # gross/taxable reflects deduc

# tax[municipality == "Rauwerderhem" & year == 1870, ..inspvrbs] # gross/taxable reflects deduc
# tax[municipality == "Rauwerderhem" & year == 1859, ..inspvrbs] # tax only, no deduc info
# tax[municipality == "Rauwerderhem" & year == 1879, ..inspvrbs] # income and gross, plausible, swapped
tax[municipality == "Rauwerderhem" & year == 1879, c("income_taxable", "income_gross") := list(income_gross, income_taxable)] # income and gross, plausible, swapped
# Rauwerderhem, 1889 not done! there is a zipfile with scans though
# tax[municipality == "Rauwerderhem" & year == 1899, ..inspvrbs] # gross and taxable, seem ok
tax[municipality == "Rauwerderhem" & year == 1899 & income_gross == 35, income_gross := 350] # gross and taxable, seem ok
# tax[municipality == "Rauwerderhem" & year == 1909, ..inspvrbs] # gross and taxable, seem ok
# tax[municipality == "Rauwerderhem" & year == 1920, ..inspvrbs] # taxable only, no deduc


# tax[municipality == "Riethoven" & year == 1869, ..inspvrbs] # no deduc info
tax[municipality == "Riethoven" & year == 1879, income_gross := tax * 200] # 
# tax[municipality == "Riethoven" & year == 1879, ..inspvrbs] # 
# tax[municipality == "Riethoven" & year == 1889, ..inspvrbs] # gross/taxable, reflects some kind of deduc but seems low
# tax[municipality == "Riethoven" & year == 1899, ..inspvrbs] # gross/taxable, reflects some kind of deduc but seems low
# tax[municipality == "Riethoven" & year == 1909, ..inspvrbs] # gross/taxable reflects deduc
# tax[municipality == "Riethoven" & year == 1920, ..inspvrbs] # gross/taxable reflects deduc

# tax[municipality == "Schinnen" & year == 1879, ..inspvrbs] # gross/taxable reflects deduc
# tax[municipality == "Schinnen" & year == 1889, ..inspvrbs] # gross/taxable reflects deduc
# tax[municipality == "Schinnen" & year == 1899, ..inspvrbs] # gross/taxable reflects deduc
# tax[municipality == "Schinnen" & year == 1909, ..inspvrbs] # taxable, seems like deduc has been applied, no gross

# tax[municipality == "Uden" & year == 1859, ..inspvrbs] # no deduc info
# tax[municipality == "Uden" & year == 1869, ..inspvrbs] # no deduc info
# tax[municipality == "Uden" & year == 1879, ..inspvrbs] # percentages given for each bracket, but deductions still applied on tax, so this is not 100% correct
tax[municipality == "Uden" & year == 1879, income_taxable :=
    fcase(
        between(tax, 0.5, 2.0), tax * 1/0.0025,
        between(tax, 2.5, 5), tax * 1/(1/3/100),
        between(tax, 5.5, 19), tax * 1/0.005,
        between(tax, 20, 40), tax * 1/0.01,
        default = NA
)] # pre-deduc tax could be as much as 33% higher
# tax[municipality == "Uden" & year == 1889, ..inspvrbs] # gross and taxable, some deduc is applied
# tax[municipality == "Uden" & year == 1899, ..inspvrbs] # gross and taxable, some deduc is applied
# tax[municipality == "Uden" & year == 1909, ..inspvrbs] # gross and taxable, deduc is applied
# tax[municipality == "Uden" & year == 1920, ..inspvrbs] # gross and taxable, deduc is applied

# tax[municipality == "Vaals" & year == 1859, ..inspvrbs] # no deduc info
# tax[municipality == "Vaals" & year == 1869, ..inspvrbs] # no deduc info
# tax[municipality == "Vaals" & year == 1879, ..inspvrbs] # no deduc info
# tax[municipality == "Vaals" & year == 1889, ..inspvrbs] # tax only, no deduc info
# tax[municipality == "Vaals" & year == 1899, ..inspvrbs] # tax only, no deduc info
# tax[municipality == "Vaals" & year == 1909, ..inspvrbs] # taxable income, no deduc info
# tax[municipality == "Vaals" & year == 1920, ..inspvrbs] # taxable and gross

# tax[municipality == "Vessem, Wintelre en Knegsel" & year == 1859, ..inspvrbs] # no deduc
# tax[municipality == "Vessem, Wintelre en Knegsel" & year == 1889, ..inspvrbs] # taxable and gross, always the same (seems correct), seems low
# tax[municipality == "Vessem, Wintelre en Knegsel" & year == 1899, ..inspvrbs] # taxable and gross, always the same (seems correct), seems low
# tax[municipality == "Vessem, Wintelre en Knegsel" & year == 1909, ..inspvrbs] # taxable and gross, deduc applied, seems low still 
# tax[municipality == "Vessem, Wintelre en Knegsel" & year == 1920, ..inspvrbs] # taxable and gross, deduc applied

# tax[municipality == "Vreeland" & year == 1879, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Vreeland" & year == 1889, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Vreeland" & year == 1899, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Vreeland" & year == 1909, ..inspvrbs] # taxable and gross, deduc applied
# tax[municipality == "Vreeland" & year == 1919, ..inspvrbs] # taxable and gross, deduc applied

# tax[municipality == "Waalwijk" & year == 1859, ..inspvrbs] # no deduc info
# tax[municipality == "Waalwijk" & year == 1869, ..inspvrbs] # taxable and gross, deduc applied, months seems applied to incomes, so correct. Scans for suppl missing 
tax[municipality == "Waalwijk" & year == 1869 & !is.na(income_gross) & !is.na(months), income_gross := income_gross * 12/months] # taxable and gross, deduc applied, months seems applied to incomes, so correct. Scans for suppl missing 
tax[municipality == "Waalwijk" & year == 1869 & !is.na(income_gross) & !is.na(months), income_taxable := income_taxable * 12/months] # taxable and gross, deduc applied, months seems applied to incomes, so correct. Scans for suppl missing 
tax[municipality == "Waalwijk" & year == 1869 & !is.na(income_gross) & !is.na(months), tax := tax * 12/months] # taxable and gross, deduc applied, months seems applied to incomes, so correct. Scans for suppl missing 

# tax[municipality == "Waalwijk" & year == 1879, ..inspvrbs][order(income_gross)] # taxable and gross, deduc applied, seems ok, maybe bit low
# tax[municipality == "Waalwijk" & year == 1889, ..inspvrbs][order(income_gross)] # taxable and gross, deduc applied, seems ok, maybe bit low

# 1900_Waalwijk is weird, there's zuiver income (entered income_taxable :)),
# then there's a multiplier, then deduction, and then a taxable income which
# is way higher than the actual income. The actual deductions are useless
# because they apply to this gian x4 number. So my take: set income_gross,
# correctly, and then set income_taxable and deductions to missing.
tax[year_mun_id == "1900_Waalwijk" & income_gross == 4200, income_gross := 42000]
# tax[year_mun_id == "1900_Waalwijk", list(income_gross, income_taxable, income_gross - income_taxable)] |> as.data.frame() # taxable and gross, deduc applied, seems ok, maybe bit low
tax[year_mun_id == "1900_Waalwijk", income_gross := income_taxable]
tax[year_mun_id == "1900_Waalwijk", income_taxable := NA]
tax[year_mun_id == "1900_Waalwijk", deductions := NA]

# tax[municipality == "Waalwijk" & year == 1909] # this is capital income, will only confuse model
# waalwijk 1909 is messed up, redone now, gross should be "vereenigd bedrag" + "reduction 25%" ,taxable should be last one
# still, do not use income_unspecified because here income_unspecified is capital_income

# tax[year_mun_id == "1920_Waalwijk", ..inspvrbs]
tax[year_mun_id == "1920_Waalwijk", income_gross := income_unspecified]
tax[year_mun_id == "1920_Waalwijk", income_unspecified := NA]
tax[year_mun_id == "1920_Waalwijk", income_taxable := income_gross - deductions] # now taxable and gross, deductions (400/600 + 50 per kid) applied
# nb waalwijk: 1920 and 1900 are still outliers compared to other years, deserves closerlook

# tax[municipality == "Weert" & year == 1899, ..inspvrbs] # no deduc info
# tax[municipality == "Weert" & year == 1909, ..inspvrbs] # no deduc info
tax[municipality == "Weert" & year == 1919, income_gross := mid + 400] # description more complex, but cannot find original scan of schedule
tax[municipality == "Weert" & year == 1919, mid := NA] # description more complex, but cannot find original scan of schedule


# tax[municipality == "Aardenburg" & year == 1849, ..inspvrbs] # no deduc info
# tax[municipality == "Aardenburg" & year == 1859, ..inspvrbs] # no deduc info
# tax[municipality == "Aardenburg" & year == 1911, ..inspvrbs] ### DEDUC INFO OMITTED: 300 subsistence + 25 for each kid, but we don't have kids...
tax[municipality == "Aardenburg" & year == 1911, income_gross := mid + 300]
tax[municipality == "Aardenburg" & year == 1911, mid := NA]
# tax[municipality == "Aardenburg" & year == 1919, ..inspvrbs] ### DEDUC INFO OMITTED: 400 subsistence + 25 for each kid
tax[municipality == "Aardenburg" & year == 1919, income_gross := mid + 400]
tax[municipality == "Aardenburg" & year == 1919, mid := NA]

# tax[municipality == "Alphen" & year == 1864, ..inspvrbs] # no deduc info

# tax[municipality == "Anloo" & year == 1911, ..inspvrbs] # taxable and gross, but gross still seems very low
# tax[municipality == "Anloo" & year == 1919, ..inspvrbs] # taxable and gross, seems ok

# tax[municipality == "Baexem" & year == 1909, ..inspvrbs] # raad income only, seems low, called belastbaar inkomen
tax[municipality == "Baexem" & year == 1909, income_taxable := income_raad] # raad income only, seems low, called belastbaar inkomen, raad not mentioned anywhere
tax[municipality == "Baexem" & year == 1909, income_raad := NA] # raad income only, seems low, called belastbaar inkomen
# tax[municipality == "Baexem" & year == 1920, ..inspvrbs] # 2nd income indeed a mystery, taxable plausible, no deduc info


# tax[municipality == "Berg en Terblijt" & year == 1899, ..inspvrbs] # no deduc info
# tax[municipality == "Berg en Terblijt" & year == 1909, ..inspvrbs] # no deduc info, taxable income low
# tax[municipality == "Berg en Terblijt" & year == 1920, ..inspvrbs] # no deduc info, taxable income low

# tax[municipality == "Bergambacht" & year == 1859, ..inspvrbs] # no deduc info
# tax[municipality == "Bergambacht" & year == 1879, ..inspvrbs] # no deduc info
# tax[municipality == "Bergambacht" & year == 1899, ..inspvrbs] # no deduc info
# tax[municipality == "Bergambacht" & year == 1909, ..inspvrbs] # gross and taxable, seems ok if slightly low

# tax[municipality == "Borculo" & year == 1866, ..inspvrbs] # no deduc info
# tax[municipality == "Borculo" & year == 1879, ..inspvrbs] # no deduc info
# tax[municipality == "Borculo" & year == 1886, ..inspvrbs] # no deduc info
# tax[municipality == "Borculo" & year == 1901, ..inspvrbs] # taxable 
tax[municipality == "Borculo" & year == 1901, income_taxable := income_unspecified] # unspec is taxable 
tax[municipality == "Borculo" & year == 1901, income_gross := income_taxable + 250] # 
# tax[municipality == "Borculo" & year == 1921, ..inspvrbs] # gross and taxable, seems ok if slightly low

# tax[municipality == "Borger" & year == 1855, ..inspvrbs] # no deduc info
# tax[municipality == "Borger" & year == 1876, ..inspvrbs] # no deduc info
# tax[municipality == "Borger" & year == 1889, ..inspvrbs] # no deduc info
# tax[municipality == "Borger" & year == 1899, ..inspvrbs] # gross and taxable, seems low
# tax[municipality == "Borger" & year == 1909, ..inspvrbs] # gross and taxable, seems low-ish
# tax[municipality == "Borger" & year == 1919, ..inspvrbs] # gross and taxable

tax[municipality == "Brummen" & year == 1909, ..inspvrbs] # taxable income, low, no deduc info
tax[year_mun_id == "1909_Brummen", income_taxable := mid]
tax[year_mun_id == "1909_Brummen", mid := NA]

# tax[municipality == "Bunnik" & year == 1859, ..inspvrbs] # no deduc info, only tells us < 200 is exempt
# tax[municipality == "Bunnik" & year == 1868, ..inspvrbs] # no deduc info
# tax[municipality == "Bunnik" & year == 1869, ..inspvrbs] # no deduc info
tax[year_mun_id == "1869_Bunnik" & tax == 229, tax := 29]
# tax[municipality == "Bunnik" & year == 1879, ..inspvrbs] # no deduc info
# tax[municipality == "Bunnik" & year == 1889, ..inspvrbs] # no deduc info
# tax[municipality == "Bunnik" & year == 1899, ..inspvrbs] # no deduc info
# tax[municipality == "Bunnik" & year == 1909, ..inspvrbs] # taxable/gross available
# tax[municipality == "Bunnik" & year == 1920, ..inspvrbs] # taxable/gross available

# tax[municipality == "Cothen" & year == 1859, ..inspvrbs] # no deduc info, lot like bunnik above
# tax[municipality == "Cothen" & year == 1869, ..inspvrbs] # no deduc info, lot like bunnik above
# tax[municipality == "Cothen" & year == 1879, ..inspvrbs] # no deduc info, lot like bunnik above
# tax[municipality == "Cothen" & year == 1889, ..inspvrbs] # no deduc info, lot like bunnik above
# tax[municipality == "Cothen" & year == 1899, ..inspvrbs] # no deduc info, lot like bunnik above

# tax[municipality == "Diever" & year == 1868, ..inspvrbs] # no deduc info
# tax[municipality == "Diever" & year == 1879, ..inspvrbs] # no deduc info
# tax[municipality == "Diever" & year == 1889, ..inspvrbs] # no deduc info
# tax[municipality == "Diever" & year == 1899, ..inspvrbs] # gross/taxable, gross seems low
# tax[municipality == "Diever" & year == 1909, ..inspvrbs] # gross/taxable, gross seems low
# tax[municipality == "Diever" & year == 1920, ..inspvrbs] # gross/taxable, no further deduc info

# tax[municipality == "Doesburg" & year == 1879, ..inspvrbs] # no deduc info, there's info in the verordeningen but it's incopmlete
# tax[municipality == "Doesburg" & year == 1889, ..inspvrbs] # no deduc info
# tax[municipality == "Doesburg" & year == 1899, ..inspvrbs] # no deduc info
# tax[municipality == "Doesburg" & year == 1909, ..inspvrbs] # no deduc info
# tax[municipality == "Doesburg" & year == 1920, ..inspvrbs] # no deduc info, schedule added, fl. 300 shoud be added
tax[municipality == "Doesburg" & year == 1920, income_gross := mid + 300] # no deduc info, schedule added, fl. 300 shoud be added
tax[municipality == "Doesburg" & year == 1920, mid := NA] # no deduc info, schedule added, fl. 300 shoud be added

# tax[municipality == "Doniawerstal" & year == 1859, ..inspvrbs] # no deduc info
# tax[municipality == "Doniawerstal" & year == 1869, ..inspvrbs] # income/gross
# tax[municipality == "Doniawerstal" & year == 1879, ..inspvrbs] # income/gross
# tax[municipality == "Doniawerstal" & year == 1900, ..inspvrbs] # income/gross

# q is what to do with these drenthe-like gross/taxable ones that seem so low
# tax[municipality == "Dwingeloo" & year == 1858, ..inspvrbs] # no deduc info
# tax[municipality == "Dwingeloo" & year == 1892, ..inspvrbs] # no deduc info
# tax[municipality == "Dwingeloo" & year == 1899, ..inspvrbs] # no deduc info
# tax[municipality == "Dwingeloo" & year == 1909, ..inspvrbs] # taxable/gross, gross seems low
# tax[municipality == "Dwingeloo" & year == 1920, ..inspvrbs] # taxable/gross, gross seems low

tax[municipality == "Edam" & year == 1859, ..inspvrbs][order(mid)][!is.na(mid)] # get income classes ("vermoedelijk inkomen"), seems low
tax[year_mun_id == "1859_Edam", income_gross := mid] # all a bit low (250), but deductions happen on tax paid, not pre-tax income
tax[year_mun_id == "1859_Edam", mid := NA] # all a bit low (250), but deductions happen on tax paid, not pre-tax income

tax[municipality == "Edam" & year == 1870, deductions := NA] # deduction is on tax, not income, so drop
tax[year_mun_id == "1870_Edam", income_gross := mid] # all a bit low (250), but deductions happen on tax paid, not pre-tax income
tax[year_mun_id == "1870_Edam", mid := NA] # all a bit low (250), but deductions happen on tax paid, not pre-tax income

tax[municipality == "Edam" & year == 1879, deductions := NA] # deduction is on tax, not income, so drop
tax[year_mun_id == "1879_Edam" & volgnummer == 325, class := 21] # mistaken 
tax[year_mun_id == "1879_Edam" & volgnummer == 325, mid := 500]
tax[year_mun_id == "1879_Edam", income_gross := mid] # all a bit low (250), but deductions happen on tax paid, not pre-tax income
tax[year_mun_id == "1879_Edam", mid := NA] # all a bit low (250), but deductions happen on tax paid, not pre-tax income
# tax[municipality == "Edam" & year == 1879, ..inspvrbs] # deduction is on tax, not income

tax[municipality == "Edam" & year == 1889, ..inspvrbs][order(mid)] # income classes ("vermoedelijk inkomen"), seems low
tax[year_mun_id == "1889_Edam", income_gross := mid] # bit low (325)
tax[year_mun_id == "1889_Edam", mid := NA]

tax[municipality == "Edam" & year == 1899, ..inspvrbs][order(mid)] # income classes ("vermoedelijk inkomen"), seems low
tax[year_mun_id == "1899_Edam", income_gross := mid] # bit low (325)
tax[year_mun_id == "1899_Edam", mid := NA]

tax[municipality == "Edam" & year == 1909, income_gross := income_taxable + 200] # as mentioned in deducs, still low, suggest above is in line thoug
tax[year_mun_id == "1909_Edam" & volgnummer == 1372, tax := 20.13]

tax[municipality == "Edam" & year == 1920, income_gross := income_taxable + 200] # as mentioned in deducs, still low, suggest above is in line thoug, same as mid


# tax[municipality == "Gorssel" & year == 1879, ..inspvrbs] # no deduc info, just taxes
# tax[municipality == "Graft" & year == 1862, ..inspvrbs] # no deduc info, just taxes
# tax[municipality == "Graft" & year == 1869, ..inspvrbs] # no deduc info, just taxes
# tax[municipality == "Graft" & year == 1879, ..inspvrbs] # no deduc info, just taxes
# tax[municipality == "Graft" & year == 1889, ..inspvrbs] # no deduc info, just taxes
# tax[municipality == "Graft" & year == 1899, ..inspvrbs] # no deduc info, just taxes
# tax[municipality == "Haamstede" & year == 1859, ..inspvrbs] # no deduc info, only taxes
# tax[municipality == "Haamstede" & year == 1869, ..inspvrbs] # no deduc info, only taxes
# tax[municipality == "Haamstede" & year == 1879, ..inspvrbs] # no deduc info, only taxes
# tax[municipality == "Haamstede" & year == 1889, ..inspvrbs] # no deduc info, only taxes
# tax[municipality == "Haamstede" & year == 1899, ..inspvrbs] # no deduc info, only taxes
# tax[municipality == "Haamstede" & year == 1909, ..inspvrbs] # gross/taxable, has deduc
tax[municipality == "Haamstede" & year == 1909 & income_gross == 50, income_gross := 500] # gross/taxable, has deduc

# tax[municipality == "Haamstede" & year == 1919, ..inspvrbs] # gross/taxable, has deduc
# tax[municipality == "Hattem" & year == 1889, ..inspvrbs] # no deduc info
# tax[municipality == "Hindeloopen" & year == 1859, ..inspvrbs] # no deduc info, just taxes
tax[municipality == "Hindeloopen" & year == 1889, ..inspvrbs] # taxable only, no indication on deduction
tax[municipality == "Hindeloopen" & year == 1899, ..inspvrbs] # taxable only, no indication on deduction
tax[municipality == "Hindeloopen" & year == 1909, ..inspvrbs] # taxable, 200 deduc mentioned on more detailed pages (source of income breakdown as well)
tax[municipality == "Hindeloopen" & year == 1909, income_gross := income_taxable + 200 + 50] # taxable, 200 deduc mentioned on more detailed pages (source of income breakdown as well) + 25 per kid breakdown (unknown but 2 seems a decent average)
tax[municipality == "Hindeloopen" & year == 1920, ..inspvrbs] # taxable only, no deduc mentioned

# tax[municipality == "Nibbixwoud" & year == 1859, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Nibbixwoud" & year == 1869, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Nibbixwoud" & year == 1880, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Nibbixwoud" & year == 1889, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Nibbixwoud" & year == 1898, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Nieuwveen" & year == 1900, ..inspvrbs] # tax only, no deduc

# tax[municipality == "Papendrecht" & year == 1859, ..inspvrbs] # tax only
# tax[municipality == "Papendrecht" & year == 1869, ..inspvrbs] # tax only
# tax[municipality == "Papendrecht" & year == 1879, ..inspvrbs] # tax only
# tax[municipality == "Papendrecht" & year == 1889, ..inspvrbs] # tax only
# tax[municipality == "Papendrecht" & year == 1899, ..inspvrbs] # tax only
# tax[municipality == "Papendrecht" & year == 1909, ..inspvrbs] # schedule, has 300 deduc
tax[municipality == "Papendrecht" & year == 1909, income_gross := mid + 300] # schedule, has 300 deduc
tax[municipality == "Papendrecht" & year == 1909, mid := NA] # schedule, has 300 deduc

# tax[municipality == "Philippine" & year == 1864, ..inspvrbs] # tax only, no deduc info
# tax[municipality == "Philippine" & year == 1872, ..inspvrbs] # tax only, no deduc info
# tax[municipality == "Philippine" & year == 1880, ..inspvrbs] # tax only, no deduc info
# tax[municipality == "Philippine" & year == 1889, ..inspvrbs] # schedule, seems low, no info
# tax[municipality == "Philippine" & year == 1899, ..inspvrbs] # scheule, ok-ish, no info
tax[year_mun_id == "1899_Philippine", income_gross := mid]
tax[year_mun_id == "1899_Philippine", mid := NA]
# tax[municipality == "Philippine" & year == 1909, ..inspvrbs] # 250 deduc from schedule, also children but not recorded
tax[municipality == "Philippine" & year == 1909, income_gross := mid + 250]
tax[municipality == "Philippine" & year == 1909, mid := NA]
# tax[municipality == "Philippine" & year == 1919, ..inspvrbs] # 400 deduc from schedule, also children but not recorded
tax[municipality == "Philippine" & year == 1919, income_gross := mid + 400]
tax[municipality == "Philippine" & year == 1919, mid := NA]

# tax[municipality == "Raamsdonk" & year == 1859, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Raamsdonk" & year == 1869, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Raamsdonk" & year == 1879, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Raamsdonk" & year == 1889, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Raamsdonk" & year == 1889, ..inspvrbs] # missing!
# tax[municipality == "Raamsdonk" & year == 1899, ..inspvrbs] # missing!
# tax[municipality == "Raamsdonk" & year == 1909, ..inspvrbs] # missing!
# raamsdonk 1889, 1899, 1909 not entered even though scans are made
# TODO: enter these as well

# tax[municipality == "Roden" & year == 1861, ..inspvrbs] # tax only
# tax[municipality == "Roden" & year == 1870, ..inspvrbs] # tax only
# tax[municipality == "Roden" & year == 1880, ..inspvrbs] # tax only
# tax[municipality == "Roden" & year == 1889, ..inspvrbs] # tax only
# tax[municipality == "Roden" & year == 1899, ..inspvrbs] # gross and taxable, taxable is weird (20pct) but ok, gross still seems very low
# tax[municipality == "Roden" & year == 1909, ..inspvrbs] # taxable/gross, seems ok
# tax[municipality == "Roden" & year == 1920, ..inspvrbs] # taxable/gross, seems ok

## from scans
# tax[municipality == "Ruinerwold" & year == 1912, ..inspvrbs] # taxable/gross, seems ok
# tax[municipality == "Ruinerwold" & year == 1920, ..inspvrbs] # taxable/gross, seems ok

# tax[municipality == "Swalmen" & year == 1890, ..inspvrbs] # tax only, no deduc info
# tax[municipality == "Swalmen" & year == 1900, ..inspvrbs] # tax only, no deduc info
# tax[municipality == "Swalmen" & year == 1909, ..inspvrbs][order(income_taxable)] # income taxable only, no deduc info
# tax[municipality == "Swalmen" & year == 1920, ..inspvrbs][order(income_taxable)] # income taxable only, no deduc info

# tax[municipality == "Twisk" & year == 1859, ..inspvrbs] # tax only
# tax[municipality == "Twisk" & year == 1866, ..inspvrbs] # tax only
# tax[municipality == "Twisk" & year == 1879, ..inspvrbs] # tax only
# tax[municipality == "Twisk" & year == 1889, ..inspvrbs] # tax only
# tax[municipality == "Twisk" & year == 1899, ..inspvrbs] # tax only
# tax[municipality == "Twisk" & year == 1908, ..inspvrbs] # tax only, 400 deduc mentioned, but not from what
# tax[municipality == "Twisk" & year == 1920, ..inspvrbs][order(income_raad)] # taxable and dedutions, implied gross seems high
tax[municipality == "Twisk" & year == 1920 & !is.na(income_raad), income_gross := income_raad + deductions]
tax[municipality == "Twisk" & year == 1920 & is.na(income_raad), income_gross := income_taxable + deductions]

# tax[municipality == "Utrecht" & year == 1879, ..inspvrbs] # taxable income correct, but very messy how it's made
tax[year_mun_id == "1879_Utrecht" & tax > 160e3, tax := 164.265]
tax[year_mun_id == "1879_Utrecht" & sheet_name == "6383 (Wijk I-M)" & wijk == "I" & volgnummer == 53, tax := 1.695]
tax[year_mun_id == "1879_Utrecht" & sheet_name == "6465 (2e suppl.)" & volgnummer == 448, tax := 19.68]

# tax[municipality == "Utrecht" & year == 1889, ..inspvrbs][order(mid)] # mid and deductions fixed, missings are missing except fix below
tax[municipality == "Utrecht" & year == 1889 & class == 81, mid := 14000] # mid and deductions fixed
tax[municipality == "Utrecht" & year == 1889 & class == 81, class := 21] # mid and deductions fixed
tax[year_mun_id == "1899_Utrecht" & sheet_name == 6621 & volgnummer == 1430, tax := 8.25]
tax[year_mun_id == "1889_Utrecht", income_gross := mid]
tax[year_mun_id == "1889_Utrecht", mid := NA]
tax[year_mun_id == "1889_Utrecht" & sheet_name == "6499 (Wijk I)" & volgnummer == 1751, tax := 79.82]

# tax[municipality == "Utrecht" & year == 1909, ..inspvrbs][order(mid)] # mid and deductions fixed
tax[municipality == "Utrecht" & year == 1909 & class == 211, list(sheet_name, volgnummer)]
tax[municipality == "Utrecht" & year == 1909 & class == 211, mid := 2175]
tax[municipality == "Utrecht" & year == 1909 & class == 211, class := 11]
tax[municipality == "Utrecht" & year == 1909 & is.na(class) & volgnummer == 712, list(sheet_name, volgnummer, class)]
tax[municipality == "Utrecht" & year == 1909 & is.na(class) & volgnummer == 712, mid := 950]
tax[municipality == "Utrecht" & year == 1909 & is.na(class) & volgnummer == 712, class := 4]
tax[year_mun_id == "1909_Utrecht", income_gross := mid]
tax[year_mun_id == "1909_Utrecht", mid := NA]
# empties seem ok


# tax[municipality == "Varik" & year == 1859, ..inspvrbs] # tax only, no dedu info
# tax[municipality == "Varik" & year == 1869, ..inspvrbs] # tax only, no dedu info
# tax[municipality == "Varik" & year == 1879, ..inspvrbs] # tax only, no dedu info
# tax[municipality == "Varik" & year == 1889, ..inspvrbs] # tax only, no dedu info
# tax[municipality == "Varik" & year == 1899, ..inspvrbs] # tax only, no dedu info

# VARIK ACTUALLY CONTAINS INCOMES, STARTS AT 25 (250 VRIJSTELLING), 50, 75, 100, 150, 250, 350, 
# TODO: add this to tax schedule
# tax[municipality == "Varik" & year == 1909, ..inspvrbs] # tax only, no dedu info
# tax[municipality == "Varik" & year == 1920, ..inspvrbs] # tax schedule, low, no deduc info
tax[year_mun_id == "1920_Varik", income_taxable := mid]
tax[year_mun_id == "1920_Varik", mid := NA]

# tax[municipality == "Vinkeveen en Waverveen" & year == 1859, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Vinkeveen en Waverveen" & year == 1869, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Vinkeveen en Waverveen" & year == 1879, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Vinkeveen en Waverveen" & year == 1889, ..inspvrbs] # tax only, no deduc, but scans seem off, should 449, kohier 1/2 weird
# tax[municipality == "Vinkeveen en Waverveen" & year == 1900, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Vinkeveen en Waverveen" & year == 1909, ..inspvrbs] # income taxable, indeed low. Scans seem to be missing?
# tax[municipality == "Vinkeveen en Waverveen" & year == 1920, ..inspvrbs] # gross and income, look fine

# tax[municipality == "Vlieland" & year == 1856, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Vlieland" & year == 1869, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Vlieland" & year == 1879, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Vlieland" & year == 1889, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Vlieland" & year == 1899, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Vlieland" & year == 1909, ..inspvrbs] # this already includes a 200 deduc
tax[year_mun_id == "1909_Vlieland", income_gross := mid]  # 200 deduc included in schedule even if it still seems a bit
tax[year_mun_id == "1909_Vlieland", mid := NA]  # 200 deduc included in schedule even if it still seems a bit
# tax[municipality == "Vlieland" & year == 1920, ..inspvrbs] # income/taxable, look good

# tax[municipality == "Warnsveld" & year == 1880, ..inspvrbs] # tax only, no deduc, not in municipal decision either

# tax[municipality == "Wilnis" & year == 1859, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Wilnis" & year == 1869, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Wilnis" & year == 1879, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Wilnis" & year == 1889, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Wilnis" & year == 1899, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Wilnis" & year == 1909, ..inspvrbs] # 300 deduc
tax[municipality == "Wilnis" & year == 1909, income_gross := income_raad + 300]
# tax[municipality == "Wilnis" & year == 1919, ..inspvrbs] # gross/taxable reflect deductions
tax[municipality == "Wilnis" & year == 1919 & is.na(income_taxable), income_taxable := 0] # gross/taxable reflect deductions
tax[municipality == "Wilnis" & year == 1920 & is.na(income_taxable), income_taxable := 0] # gross/taxable reflect deductions

# tax[municipality == "Woubrugge" & year == 1859, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Woubrugge" & year == 1869, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Woubrugge" & year == 1879, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Woubrugge" & year == 1889, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Woubrugge" & year == 1899, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Woubrugge" & year == 1919, ..inspvrbs] # gross/taxable reflect deductions
tax[municipality== "Woubrugge" & year == 1919 & income_gross == 0, income_gross := NA] # one value only

# TODO: check 1809, 1899
# tax[municipality == "Zaamslag" & year == 1919, ..inspvrbs] # schedule, 450 deduc manually processed in schedule (+ kids but not registered)
tax[year_mun_id == "1919_Zaamslag", income_gross := mid] # schedule, 450 deduc manually processed in schedule (+ kids but not registered)
tax[year_mun_id == "1919_Zaamslag", income_taxable := mid - 450] # schedule, 450 deduc manually processed in schedule (+ kids but not registered)
tax[year_mun_id == "1919_Zaamslag", mid := NA] # schedule, 450 deduc manually processed in schedule (+ kids but not registered)

# tax[municipality == "Zaandijk" & year == 1859, ..inspvrbs] # tax only
# tax[municipality == "Zaandijk" & year == 1869, ..inspvrbs] # tax only
# tax[municipality == "Zaandijk" & year == 1879, ..inspvrbs] # inc unsp., seems gross, no info
# tax[municipality == "Zaandijk" & year == 1889, ..inspvrbs]# inc unsp., seems gross, no info
# tax[municipality == "Zaandijk" & year == 1909, ..inspvrbs] # taxable income, deduction not mentioned
# tax[municipality == "Zaandijk" & year == 1920, ..inspvrbs] # gross does not yet include 500 base deduc + lots of NA = 0, reconstruct from raad/income/deduc
# tax[municipality == "Zaandijk" & year == 1920, ..inspvrbs] # gross/taxable reflect deductions
tax[municipality == "Zaandijk" & year == 1920 & is.na(deductions), deductions := 0]
tax[municipality == "Zaandijk" & year == 1920 & is.na(income_raad), income_raad := income_taxable]
tax[municipality == "Zaandijk" & year == 1920, income_gross := income_raad + 500 + deductions] # gross/taxable reflect deductions

# tax[municipality == "Zierikzee" & year == 1862, ..inspvrbs] # tax only, no deduc
# tax[municipality == "Zierikzee" & year == 1869, ..inspvrbs] # schedule, looks like gross
tax[year_mun_id == "1869_Zierikzee", income_gross := mid]
tax[year_mun_id == "1869_Zierikzee", mid := NA]
tax[municipality== "Zierikzee" & year == 1879, income_gross := NA] # contains one value only, misleads model
tax[municipality== "Zierikzee" & year == 1879 & income_taxable == 22, income_taxable := NA] # contains one value only, misleads model
tax[municipality== "Zierikzee" & year == 1879 & deductions == 22, deductions := NA] # contains one value only, misleads model

# tax[municipality == "Zierikzee" & year == 1879, ..inspvrbs] # schedule, looks like taxable, autofilled raad things fixed. Raad corrections needs look. Not transferred to gross here because not sure
tax[municipality == "Zierikzee" & year == 1879 & grepl("naar .* klasse", notes_register)]
drop_zierikzee = tax[, which(municipality == "Zierikzee" & year == 1879 & grepl("naar .* klasse", notes_register))]
tax = tax[-drop_zierikzee]

# tax[municipality == "Zierikzee" & year == 1889, ..inspvrbs] # schedule, looks like taxable, autofilled raad things fixed. Raad corrections
drop_zierikzee = tax[, which(municipality == "Zierikzee" & year == 1889 & grepl("naar .* klasse", notes_register))]
tax = tax[-drop_zierikzee]

# tax[municipality == "Zierikzee" & year == 1899, ..inspvrbs] # schedule, looks like taxable, autofilled raad things fixed. Raad corrections
drop_zierikzee = tax[, which(municipality == "Zierikzee" & year == 1899 & grepl("naar .* klasse", notes_register))]
tax = tax[-drop_zierikzee]
# tax[municipality == "Zierikzee" & year == 1909, ..inspvrbs] # schedule, def taxable, autofilled raad things fixed. Raad corrections
drop_zierikzee = tax[, which(municipality == "Zierikzee" & year == 1909 & grepl("naar .* klasse", notes_register))]
tax = tax[-drop_zierikzee]
tax[municipality == "Zierikzee" & year == 1909, income_taxable := mid] # schedule, def taxable, autofilled raad things fixed. Raad corrections
tax[municipality == "Zierikzee" & year == 1909, mid := NA] # schedule, def taxable, autofilled raad things fixed. Raad corrections

# tax[municipality == "Zierikzee" & year == 1919, ..inspvrbs] # schedule, def taxable, autofilled raad things fixed. Raad corrections
tax[municipality == "Zierikzee" & year == 1919 & grepl("van .*e", notes_register), notes_register]
drop_zierikzee = tax[, which(municipality == "Zierikzee" & year == 1919 & grepl("naar .*e", notes_register))]
tax = tax[-drop_zierikzee]
# also afgevoerd but extremely rare
tax[municipality == "Zierikzee" & year == 1919, income_taxable := mid] # schedule, def taxable, autofilled raad things fixed. Raad corrections
tax[municipality == "Zierikzee" & year == 1919, mid := NA] # schedule, def taxable, autofilled raad things fixed. Raad corrections

# tax[municipality == "Zuid-Scharwoude" & year == 1859, ..inspvrbs] # tax only, no info
# tax[municipality == "Zuid-Scharwoude" & year == 1869, ..inspvrbs] # tax only, no info
# tax[municipality == "Zuid-Scharwoude" & year == 1879, ..inspvrbs] # tax only, no info
# tax[municipality == "Zuid-Scharwoude" & year == 1889, ..inspvrbs] # tax only, no info
# tax[municipality == "Zuid-Scharwoude" & year == 1899, ..inspvrbs] # tax only, no info
# tax[municipality == "Zuid-Scharwoude" & year == 1909, ..inspvrbs] # tax only, no info

# tax[municipality == "Zuidwolde" & year == 1859, ..inspvrbs] # tax only
# tax[municipality == "Zuidwolde" & year == 1869, ..inspvrbs] # tax only
# tax[municipality == "Zuidwolde" & year == 1879, ..inspvrbs] # tax only
# tax[municipality == "Zuidwolde" & year == 1889, ..inspvrbs] # tax only
# tax[municipality == "Zuidwolde" & year == 1899, ..inspvrbs] # income gross, matches scan, seems low, drente
# tax[municipality == "Zuidwolde" & year == 1902, ..inspvrbs] # taxable/gross, checks out
# tax[municipality == "Zuidwolde" & year == 1909, ..inspvrbs] # taxable/gross, checks out
# tax[municipality == "Zuidwolde" & year == 1919, ..inspvrbs] # taxable/gross, checks out

# tax[municipality == "het Bildt" & year == 1869, ..inspvrbs] # two taxable incomes here, add 300 to make gross to make it correct
tax[municipality == "het Bildt" & year == 1869, income_gross := income_gross + 300] # two taxable incomes here, add 300 to make gross to make it correct
# tax[municipality == "het Bildt" & year == 1879, ..inspvrbs] # taxable/gross
# tax[municipality == "het Bildt" & year == 1889, ..inspvrbs] # taxable/gross
# tax[municipality == "het Bildt" & year == 1899, ..inspvrbs] # taxable/gross
# tax[municipality == "het Bildt" & year == 1909, ..inspvrbs] # now dropped
# tax[municipality == "het Bildt" & year == 1920, ..inspvrbs] # taxable/gross

# tax[municipality == "Beek (L.)" & year == 1860, ..inspvrbs] # tax only
# tax[municipality == "Beek (L.)" & year == 1869, ..inspvrbs] # tax only
# tax[municipality == "Beek (L.)" & year == 1879, ..inspvrbs] # tax only
# tax[municipality == "Beek (L.)" & year == 1889, ..inspvrbs] # tax only
# tax[municipality == "Beek (L.)" & year == 1899, ..inspvrbs] # tax only
# tax[municipality == "Beek (L.)" & year == 1909, ..inspvrbs]
tax[year_mun_id == "1909_Beek_(L.)" & is.na(income_gross), income_gross := income_taxable + 200] # in metadata, not in scan
# tax[municipality == "Beek (L.)" & year == 1920, ..inspvrbs] # gross/taxable available

tax[municipality== "het Bildt" & year == 1920 & income_gross == 3, income_gross := NA] # one value only


# tax[year_mun_id == "1878_Enschede", ..inspvrbs][order(income_gross)] # gross only, seems correct
# tax[year_mun_id == "1890_Enschede", ..inspvrbs][order(income_gross)]
# tax[year_mun_id == "1899_Enschede", ..inspvrbs][order(income_gross)]
# enschede tax amounts mistaken
tax[year_mun_id == "1899_Enschede" & income_gross == 450, tax := 2.74]


# tax[year_mun_id == "1909_Enschede", ..inspvrbs][order(income_taxable)]

# income clearly is income taxable, in 1919 we find  average deduction
# (varied) 575 from the kohieren. 450-700 is the range. In 1899 the actual
# incomes are reported even if they are called belastbaar. Lowest is 400-500.
# In 1916 in lonneker, it was 350 (thought to be insufficient at that point),
# but this is not enschede. But probably a minimum. I'd say they're deducting
# 400 in 1899 probably, so more than that as well.

# should be 450 https://resolver.kb.nl/resolve?urn=MMSAEN01:000041046:mpeg21:a0002
tax[year_mun_id == "1909_Enschede", income_gross := income_taxable + 200] # 400 as conservative estimate, maybe should be a lower number + child deducitons

# tax[year_mun_id == "1919_Enschede", ..inspvrbs][order(income_gross)]
tax[year_mun_id == "1919_Enschede", mid := NA] # mid is taxable, drop. Rest already fixed in enschede1919.R

tax[year_mun_id == "1870_Utrecht", ..inspvrbs][order(income_taxable)] # taxable, that rijksopscenten mess
tax[year_mun_id == "1870_Utrecht", .N, by = round(income_taxable, -1)] # taxable, that rijksopscenten mess
tax[year_mun_id == "1870_Utrecht" & volgnummer == 98 & sheet_name == "data_wijk_G"]
# this is off by factor 100. there are more
tax[year_mun_id == "1870_Utrecht"][order(tax / income_taxable), .SD, .SDcols = c(inspvrbs, "taxrate")][1:20]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_G" & volgnummer == 98, tax := tax / 100]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_D" & volgnummer == 118, tax := 24.35]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_M" & volgnummer == 38, tax := 4.81]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 135, income_taxable := 61.60]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 135, tax := 5.96]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 136, income_taxable := 987.58]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 136, tax := 14.76]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 139, income_taxable := 90.50]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 139, tax := 1.29]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 132, income_taxable := 72.49]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 132, tax := 1.03]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 134, income_taxable := 386.60]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 134, tax := 5.03]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 133, income_taxable := 324.40]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 133, tax := 3.37]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 137, income_taxable := 269.20]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 137, tax := 3.15]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 138, income_taxable := 76.20]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 138, tax := 5.96]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 139, income_taxable := 90.50]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 139, tax := 1.29]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 140, income_taxable := 2105.65]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 140, tax := 27.37]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 40, tax := 1.87]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_A" & volgnummer == 75, tax := 1.96]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_I" & volgnummer == 146, tax := 4.33]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_K" & volgnummer == 111, income_taxable := 1160.83]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 40, tax := 1.87]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_M" & volgnummer == 388, tax := 1.48]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_M" & volgnummer == 21, tax := 5.48]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 252, tax := 1.23]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 207, tax := 66.07]
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_L" & volgnummer == 138, tax := 3.94]
# L-135 seems correct
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_D" & volgnummer == 111, income_taxable := 2228.12]
## 2supl-252 seems correct though maybe it's the case that " in tax means none rather than "as above"
tax[year_mun_id == "1870_Utrecht" & sheet_name == "data_wijk_C" & volgnummer == 14, tax := 5.15]
# M-38 seems correct

tax[year_mun_id == "1879_Utrecht" & sheet_name == "6381 (Wijk D-F)" & wijk == "D" & volgnummer == 184, tax := 14.82]
tax[year_mun_id == "1879_Utrecht" & sheet_name == "6381 (Wijk D-F)" & wijk == "D" & volgnummer == 326, tax := 17.93]
tax[year_mun_id == "1879_Utrecht" & sheet_name == "6381 (Wijk D-F)" & wijk == "F" & volgnummer == 214, tax := 29.03]
tax[year_mun_id == "1879_Utrecht" & sheet_name == "6382 (Wijk G-H)" & wijk == "G" & volgnummer == 398, tax := 216.22]
tax[year_mun_id == "1879_Utrecht" & sheet_name == "6383 (Wijk I-M)" & wijk == "L" & volgnummer == 325, tax := 30.88]

# tax[year_mun_id == "1899_Utrecht", ..inspvrbs][order(mid)] # schedule, seems ok
tax[year_mun_id == "1899_Utrecht", income_gross := mid]
tax[year_mun_id == "1899_Utrecht", mid := NA]
# tax[year_mun_id == "1919_Utrecht", ..inspvrbs][order(income_gross)] # taxable/gross, looks good
