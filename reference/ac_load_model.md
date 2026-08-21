# Load Actinet Model

Load Actinet Model

## Usage

``` r
ac_load_model(
  classifier = c("walmsley", "willetts"),
  model_path = NULL,
  check_md5 = TRUE,
  force_download = FALSE,
  as_python = TRUE
)

ac_model_filename(classifier = c("walmsley", "willetts"))

ac_download_model(
  model_path,
  classifier = c("walmsley", "willetts"),
  check_md5 = TRUE,
  ...
)
```

## Arguments

- classifier:

  type of the model: either `walmsley` or `willetts`

- model_path:

  the file path to the model. If on disk, this can be re-used and not
  re-downloaded. If `NULL`, will download to the temporary directory

- check_md5:

  Do a MD5 checksum on the file

- force_download:

  force a download of the model, even if the file exists

- as_python:

  Keep model object as a python object

- ...:

  for `ac_download_model`, additional arguments to pass to
  [`curl::curl_download()`](https://jeroen.r-universe.dev/curl/reference/curl_download.html)

## Value

A model from Python. `ac_download_model` returns a model file path.
