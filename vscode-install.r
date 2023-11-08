# Dependencies ----

if (!require(covr)) install.packages("covr")
if (!require(DBItest)) install.packages("DBItest")
if (!require(devtools)) install.packages("devtools")
if (!require(cpp11)) install.packages("cpp11")

# Vendoring ----

# Run only when we want to update the vendored code

vendor_dir <- "./src/vendor/cpp11"

if (dir.exists(vendor_dir)) {
    unlink(vendor_dir, recursive = TRUE)
}

cpp11::cpp_vendor(vendor_dir)

try(dir.create(file.path(vendor_dir, "cpp11"), recursive = TRUE))

finp <- list.files(file.path(vendor_dir, "inst/include"), recursive = TRUE, full.names = TRUE)

for (f in finp) {
    # remove inst/include/ for each file
    file.rename(f, gsub("inst/include/", "", f))
}

unlink(file.path(vendor_dir, "inst"), recursive = TRUE)

# Pacha's note: We need to touch the Makefile
# the key line is PKG_CPPFLAGS += -I../inst/include

# read Makevars
makevars <- readLines("src/Makevars.in")

# if the "PKG_CPPFLAGS ..." line does not end with
vendor_line <- " -I../src/vendor/cpp11"

# then add it at the end of the same line

cppflags_line <- grep("^PKG_CPPFLAGS", makevars)

if (!grepl(vendor_line, makevars[cppflags_line])) {
    makevars[cppflags_line] <- paste0(makevars[cppflags_line], vendor_line)
    writeLines(makevars, "src/Makevars.in")
}

# same for Makevars.win
makevars_win <- readLines("src/Makevars.win")

cppflags_line_win <- grep("^PKG_CPPFLAGS", makevars_win)

if (!grepl(vendor_line, makevars_win[cppflags_line_win])) {
    makevars_win[cppflags_line_win] <- paste0(makevars_win[cppflags_line_win], vendor_line)
    writeLines(makevars_win, "src/Makevars.win")
}

# also important: vendoring requires to remove the cpp11 line in LinkingTo
# in DESCRIPTION

description <- readLines("DESCRIPTION")

# if there is a line with "cpp11,", remove it
if ("cpp11," %in% description) {
    description <- description[-grep("cpp11,", description)]
    writeLines(description, "DESCRIPTION")
}

# Install and check ----

devtools::install(upgrade = "never")

# for a full check
# apt install devscripts qpdf
devtools::check()
