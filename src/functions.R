
mypar = function(...){
    par(...,
        bty = "l",
        mar = c(4, 3, 2, 1),
        mgp = c(1.7, .5, 0),
        tck=-.01,
        font.main = 1
    )
}

safe_paste0 <- function(...) {

    # Apply fcoalesce to every argument, turning NAs into empty strings
    clean_cols <- lapply(list(...), data.table::fcoalesce, "")

    do.call(paste0, clean_cols)
}

# Alphabetical share, measured as share following lower ordered
calc_share_alphabetical = function(x){
    mean(x >= shift(x), na.rm = TRUE)
}

top_income_share = function(y, q){
    if (all(is.na(y)))
        return(NA_real_)
    y = y[!is.na(y)]
    y = sort(y, decreasing = TRUE)
    n = length(y)
    return(
        sum(head(y, n*q)) / sum(y)
    )
}

qnt = function(x, probs = c(0.25, 0.5, 0.75)){
    # quantiles but returnes as a data.table
    out = quantile(x[!is.na(x)], probs = probs)
    return(as.data.table(out, keep.rownames = TRUE))
}
