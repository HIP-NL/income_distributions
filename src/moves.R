# Make sure data is in original order
setorder(tax, "row")

tax[, consecutive_moves := rleid(moved_address)]

# Check if full name new address is same as previous one
tax[, sim_prev := stringdist::stringsim(fullname, shift(fullname, type = "lead")), by = year_mun_id]

# Group identifier for movers
tax[(moved_address == 1 & sim_prev >= 0.9), mover_id := .I, by = year_mun_id]
tax[, mover_id := fifelse(is.na(mover_id), shift(mover_id, type = "lag"), mover_id), by = year_mun_id]

# Assign address numbers to movers
tax[!is.na(mover_id), address_nr := 1:.N, by = mover_id]

# Extract new addresses and merge back to the original observation
movers_new_address = tax[address_nr == 2, list(
    mover_id,
    place_new = place,
    street_new = street,
    house_nr_street_new = house_nr_street,
    wijk_new = wijk,
    house_nr_wijk_new = house_nr_wijk
)]

tax = merge(
    tax[is.na(address_nr) | address_nr == 1],
    movers_new_address,
    by = "mover_id",
    all.x = TRUE
)

# Restore original row order after merge
setorder(tax, "row")
