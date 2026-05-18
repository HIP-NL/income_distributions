library("stringdist")
library("data.table")
library("zoo")

setorder(tax, "row") # NB diff(row) > 1 because some data is dropped earlier

# ------------------------------------------------------------------------------
# 1. ADDRESS IMPUTATION
# ------------------------------------------------------------------------------

# Define pairs: Column Name = Max Gap Allowed
# We'll use 9 for numbers and 25 for street/wijk (adjust as needed)
impute_map <- list(
  house_nr_wijk   = 9,
  house_nr_street = 9,
  wijk            = 25,
  street          = 25
)

for (col in names(impute_map)) {

    depth <- impute_map[[col]]

    # 1. Standardize empty strings to NA
    tax[get(col) == "", (col) := NA_character_]

    # 2. Identify gap sizes for NA blocks
    # rleid tracks contiguous blocks of NA vs Non-NA
    tax[, temp_gap := .N, by = .(rleid(is.na(get(col))), sheet_name, page_nr)]

    # 3. Generate the forward-fill values
    tax[, temp_filled := zoo::na.locf(get(col), na.rm = FALSE), by = .(sheet_name, page_nr)]

    # 4. Apply filled values if the gap is within the specific depth
    tax[is.na(get(col)) & temp_gap <= depth, (col) := temp_filled]

    # Cleanup temp columns
    tax[, c("temp_gap", "temp_filled") := NULL]
}

# ------------------------------------------------------------------------------
# 2. CROSS-SHEET DUPLICATES (MAIN VS. SUPPLETOIR)
# ------------------------------------------------------------------------------

tax[, surname_address := safe_paste0(street, house_nr_street, wijk, house_nr_wijk, surname)]
tax[, fullname_address := safe_paste0(street, house_nr_street, wijk, house_nr_wijk, firstnames, initials, surname, suffix)]

tax[, sheet_count := rleid(sheet_name), by = year_mun_id]
tax[, full_dupl := duplicated(fullname_address) | duplicated(fullname_address, fromLast = TRUE), by = year_mun_id]

# Currently we don't do this because it's not sure what's in the suppletoirs.

if (do_cross_sheet_duplicates){
    # Identify records that appear in multiple sheets where we want to keep the latest
    tax[, drop := full_dupl == TRUE & any(sheet_count > 1) & sheet_count != max(sheet_count), by = list(year_mun_id, fullname_address)]

    # Extract the "Source" data (the very last observation for every ID)
    cols_to_update = setdiff(names(tax), c("fullname_address", "year_mun_id", "drop"))
    last_data = tax[full_dupl == TRUE, .SD[.N], by = list(year_mun_id, fullname_address)]

    # Perform the "Update-on-Join": overwrite original columns with the last sheet's values
    tax[last_data, (cols_to_update) := mget(paste0("i.", cols_to_update)), on = .(year_mun_id, fullname_address)]

    # Drop the redundant suppletoir rows to preserve the original household structure
    tax = tax[drop != TRUE | is.na(drop)]    
}

# ------------------------------------------------------------------------------
# 3. FIND BLOCKS THAT ARE NOT SAFE TO IDENTIFY
# ------------------------------------------------------------------------------

setorder(tax, row)

# ignore suppletoir which has a different logic
tax[, share_alphabetical := calc_share_alphabetical(stringi::stri_sub(unique(tolower(surname[suppletoir == FALSE])), 1, 2)), by = list(year_mun_id)]
# random words max out at about 0.6, but 0.6-0.7 is a mixing zone


not_alpha_munics = readLines("./dat/not_alpha_year_mun_id.txt") # confirmed not alphabetical even though they have high rates

# nb eindhoven within tax class is alpha, ditto de zierikzees, ditto enschede, ditto haamstede
alpha_munics = readLines("./dat/alpha_year_mun_id.txt") # confirmed not alphabetical
tax[, alphabetical_register := year_mun_id %in% alpha_munics]

tax[, synthaddress := safe_paste0(year_mun_id, place, street, house_nr_street, wijk, house_nr_wijk), by = year_mun_id]
tax[, ttr_address := uniqueN(synthaddress[suppletoir == FALSE]) / sum(suppletoir == FALSE), by = year_mun_id]

tax[, no_household_inference := alphabetical_register & (ttr_address < 0.6)]




# ------------------------------------------------------------------------------
# 6. HOUSEHOLD IDENTIFICATION
# ------------------------------------------------------------------------------

# is there value in doing volgnummer == shift(volgnummer?)
tax[no_household_inference == TRUE, mean(volgnummer == shift(volgnummer), na.rm = TRUE), by = year_mun_id][order(-V1)][1:20]
# this barely every happens

# Recompute string similarities for households after cleaning
tax[, surname_address_sim := stringsim(surname_address, shift(surname_address, fill = surname_address[1]), method = "jw"), by = year_mun_id]

threshold = 0.9

# Create household identifiers
# hhid groups consecutive rows with highly similar surname+address
tax[, hhid := 1 + cumsum(surname_address_sim < threshold), by = year_mun_id]

# hhid2 strictly separates on exact address string changes within an hhid
tax[, hhid2 := paste0(hhid, "-", rleid(safe_paste0(street, house_nr_street, wijk, house_nr_wijk))), by = list(year_mun_id, hhid)]

# Set a global household ID across municipalities if needed, from hhid2
tax[, global_hhid := paste0(year_mun_id, "_", hhid2)]

