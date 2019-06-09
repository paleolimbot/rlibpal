
library(tidyverse)

# Download and extract -------

curl::curl_download(
  "https://github.com/Pana/pal/archive/master.zip",
  "data-raw/libpal.zip"
)

if (dir.exists("data-raw/pal-master")) unlink("data-raw/pal-master", recursive = TRUE)
utils::unzip("data-raw/libpal.zip", exdir = "data-raw")

# Collect source files and header files -----------

src_dir <- "data-raw/pal-master/src/pal"
include_dir <- "data-raw/pal-master/src/includes"

src_files <- tibble(
  relative_path = list.files(src_dir, "\\.(hpp|cpp|h)$"),
  path = file.path(src_dir, relative_path),
  file = basename(path)
)

header_files <- tibble(
  relative_path = list.files(include_dir, "\\.h$", recursive = TRUE),
  path = file.path(include_dir, relative_path),
  file = basename(path)
)

if (dir.exists("data-raw/pal-src")) unlink("data-raw/pal-src", recursive = TRUE)
dir.create("data-raw/pal-src")

file.copy(src_files$path, "data-raw/pal-src")
file.copy(header_files$path, "data-raw/pal-src")

# Modify sources to compile in R ----------

# references to files in the "includes" folder are in the form
# `#include <pal/palexception.h>`
# now they need to be
# `#include "palexception.h"`

for (file in list.files("data-raw/pal-src", full.names = TRUE)) {

  file_txt <- read_file(file)

  # fix code in the form cout|cerr << ... and exit(...)
  if(str_detect(file_txt, "std::(cout|cerr)")) {
    file_txt <- file_txt %>%
      str_replace("^", "#include <Rcpp.h>\n") %>%
      str_replace_all("std::(cout|cerr)", "Rcpp::R\\1") %>%
      str_replace_all("exit\\s*\\([^)]*\\)", 'Rcpp::stop("\\0")')
  }

  # fix code in the form v?fprintf((stderr|stdout))
  if(str_detect(file_txt, "printf.*?(stderr|stdout)")) {
    file_txt <- file_txt %>%
      str_replace("^", "#include <R.h>\n") %>%
      str_replace_all("vfprintf\\s*\\(\\s*stdout,\\s*", "Rvprintf(") %>%
      str_replace_all("vfprintf\\s*\\(\\s*stderr,\\s*", "REvprintf(") %>%
      str_replace_all("fprintf\\s*\\(\\s*stderr,\\s*", "REprintf(")
  }

  file_txt %>%
    str_replace_all("#include\\s+<pal/([a-z]+).h>", '#include "\\1.h"') %>%
    str_replace_all("#include\\s+<config.h>", '#include "config.h"') %>%
    write_file(file)
}

# Copy sources to the src/ folder ---------

ignored_files <- c("Makevars.in", "Makevars.win", "RcppExports.cpp", "rlibpal.cpp", "config.h")
list.files("src") %>%
  setdiff(ignored_files) %>%
  file.path("src", .) %>%
  unlink()

file.copy(list.files("data-raw/pal-src", full.names = TRUE), "src")

# Cleanup ---------

unlink("data-raw/libpal.zip")
unlink("data-raw/pal-master", recursive = TRUE)
unlink("data-raw/pal-src", recursive = TRUE)
