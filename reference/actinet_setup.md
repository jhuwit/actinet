# Check the `actinet` Python Module

Check the `actinet` Python Module

## Usage

``` r
have_actinet()

actinet_check()

actinet_version()
```

## Value

A logical value indicating whether the `actinet` Python module is
available.

## Examples

``` r
# \donttest{
  if (have_actinet()) {
     actinet_version()
  }
#> [1] "0.7.2"
# }
```
