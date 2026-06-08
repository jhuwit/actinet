
<!-- README.md is generated from README.Rmd. Please edit that file -->

# actinet

<!-- badges: start -->

[![R-CMD-check](https://github.com/jhuwit/actinet/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/jhuwit/actinet/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/jhuwit/actinet/graph/badge.svg)](https://app.codecov.io/gh/jhuwit/actinet)
<!-- badges: end -->

The goal of `actinet` is to wrap up the
<https://github.com/OxWearables/actinet> algorithm.

# Installation

## Install `actinet` Python Module

See <https://github.com/OxWearables/actinet?tab=readme-ov-file#install>
for how to install the `actinet` python module. In the new `reticulate`,
you can do this via:

``` r
Sys.setenv(
  RETICULATE_PYTHON = "managed"
)
reticulate::py_require("actinet==0.7.2", python_version = "3.10")
sc <- reticulate::import("actinet")
```

This will install actinet via `uv` **every time** you run the command a
new time.

You can also install a conda environment via:

``` r
envname = "actinet"
reticulate::conda_create(envname = envname, packages = c("python=3.10"))
Sys.unsetenv("RETICULATE_PYTHON")
reticulate::use_condaenv(envname)
reticulate::py_install("actinet", envname = envname, method = "conda", pip = TRUE)
```

Once this is finished, you should be able to check this via:

``` r
actinet::have_actinet()
```

The `actinet_check` function can determine if the `actinet` module can
be loaded and run:

``` r
actinet::actinet_check()
#> [1] TRUE
```

In some cases, you ay want to set `RETICULATE_PYTHON` variable:

``` r
clist = reticulate::conda_list()
Sys.setenv(RETICULATE_PYTHON = clist$python[clist$name == "actinet"])
reticulate::use_condaenv("actinet")
```

# Usage

## Running `actinet` (file)

The main function is `actinet::actinet`, which takes can take in a file
directly:

``` r
library(actinet)
library(dplyr)
#> Warning: package 'dplyr' was built under R version 4.4.3
#> 
#> Attaching package: 'dplyr'
#> The following objects are masked from 'package:stats':
#> 
#>     filter, lag
#> The following objects are masked from 'package:base':
#> 
#>     intersect, setdiff, setequal, union
library(ggplot2)
#> Warning: package 'ggplot2' was built under R version 4.4.3
library(tidyr)
#> Warning: package 'tidyr' was built under R version 4.4.1
file = system.file("extdata/P30_wrist100.csv.gz", package = "actinet")
if (actinet_check()) {
  out = actinet(file = file)
}
#> Warning in normalizePath(outdir, winslash = "/"):
#> path[1]="/var/folders/1s/wrtqcpxn685_zk570bnx9_rr0000gr/T//RtmpNYuoYa/file1301f1a68ebdc":
#> No such file or directory
#> Checking Data
```

Let’s see inside the output, which is a list of values, namely a
`data.frame` of `steps` with the time (in 10s increments) and the number
of steps in those 10 seconds, a `data.frame` named `walking` which has
indicators for if there is walking within that 10 second period:

``` r
names(out)
#> [1] "outdir_passed" "outdir"        "outfiles"
str(out)
#> List of 3
#>  $ outdir_passed: chr "/var/folders/1s/wrtqcpxn685_zk570bnx9_rr0000gr/T//RtmpNYuoYa/file1301f1a68ebdc"
#>  $ outdir       : chr "/var/folders/1s/wrtqcpxn685_zk570bnx9_rr0000gr/T//RtmpNYuoYa/file1301f1a68ebdc/P30_wrist100.csv"
#>  $ outfiles     : chr [1:3] "/var/folders/1s/wrtqcpxn685_zk570bnx9_rr0000gr/T//RtmpNYuoYa/file1301f1a68ebdc/P30_wrist100.csv/P30_wrist100.cs"| __truncated__ "/var/folders/1s/wrtqcpxn685_zk570bnx9_rr0000gr/T//RtmpNYuoYa/file1301f1a68ebdc/P30_wrist100.csv/P30_wrist100.cs"| __truncated__ "/var/folders/1s/wrtqcpxn685_zk570bnx9_rr0000gr/T//RtmpNYuoYa/file1301f1a68ebdc/P30_wrist100.csv/P30_wrist100.csv-Daily.csv.gz"
```
