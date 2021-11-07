#' Z85 Encoding
#'
#' Encodes binary data (a raw vector) as ascii text using Z85 encoding format
#' @usage base85_encode(rawdata)
#' @param rawdata A raw vector
#' @return A string representation of the raw vector.
#' @details
#' Z85 is a binary to ascii encoding format created by Pieter Hintjens in 2010 and is part of the ZeroMQ RFC.
#' The encoding has a dictionary using 85 out of 94 printable ASCII characters.
#' There are other base 85 encoding schemes, including Ascii85, which is popularized and used by Adobe.
#' Z85 is distinguished by its choice of dictionary, which is suitable for easier inclusion into source code for many programming languages.
#' The dictionary excludes all quote marks and other control characters, and requires no special treatment in R and most other languages.
#' Note: although the official specification restricts input length to multiples of four bytes, the implementation here works with any input length.
#' The overhead (extra bytes used relative to binary) is 25%. In comparison, base 64 encoding has an overhead of 33.33%.

#' @references https://rfc.zeromq.org/spec/32/
#' @name base85_encode
NULL

#' Z85 Decoding
#'
#' Decodes a Z85 encoded string back to binary
#' @usage base85_decode(encoded_string)
#' @param encoded_string A string
#' @return The original raw vector.
#' @name base85_decode
NULL

#' basE91 Encoding
#'
#' Encodes binary data (a raw vector) as ascii text using basE91 encoding format
#' @usage base91_encode(rawdata, quote_character = "\"")
#' @param rawdata A raw vector
#' @param quote_character The character to use in the encoding, replacing the double quote character. Must be either a single quote (`"'"`), a double quote
#'   (`"\""`) or a dash (`"-"`).
#' @return A string representation of the raw vector.
#' @details
#' basE91 (capital E for stylization) is a binary to ascii encoding format created by Joachim Henke in 2005.
#' The overhead (extra bytes used relative to binary) is 22.97% on average. In comparison, base 64 encoding has an overhead of 33.33%.
#' The original encoding uses a dictionary of 91 out of 94 printable ASCII characters excluding `-` (dash), `\` (backslash) and `'` (single quote).
#' The original encoding does include double quote characters, which are less than ideal for strings in R. Therefore,
#' you can use the `quote_character` parameter to substitute dash or single quote.
#' @references http://base91.sourceforge.net/
base91_encode <- function(rawdata, quote_character = "\"") {
  if(!quote_character %in% c("\"", "'", "-")) {
    stop("quote_character must be a dash, single quote or double quote.")
  }
  result <- .Call(`_qs_c_base91_encode`, rawdata)
  gsub("\"", quote_character, result)
}

#' basE91 Decoding
#'
#' Decodes a basE91 encoded string back to binary
#' @usage base91_decode(encoded_string)
#' @param encoded_string A string
#' @return The original raw vector.
base91_decode <- function(encoded_string) {
  stopifnot(length(encoded_string) == 1)
  has_double_quote <- grepl("\"", encoded_string)
  has_single_quote <- grepl("'", encoded_string)
  has_dash <- grepl("-", encoded_string)
  if(has_double_quote + has_single_quote + has_dash > 1) {
    stop("Format error: dash, single quote and double quote characters are mutually exclusive for base91 encoding.")
  }
  encoded_string <- gsub("'", "\"", encoded_string)
  encoded_string <- gsub("-", "\"", encoded_string)
  .Call(`_qs_c_base91_decode`, encoded_string)
}

#' Encode and compress a file or string
#'
#' A helper function for encoding and compressing a file or string to ascii using [base91_encode()] and [qserialize()] with the highest compression level.
#' @usage encode_source(file = NULL, string = NULL, width = 120)
#' @param file The file to encode (if `string` is not NULL)
#' @param string The string to encode (if `file` is not NULL)
#' @param width The output will be broken up into individual strings, with `width` being the longest allowable string.
#' @return A CharacterVector in base91 representing the compressed original file or string.
encode_source <- function(file = NULL, string = NULL, width = 120) {
  if(!is.null(file)) {
    n <- file.info(file)$size
    x <- readChar(con = file, nchars=n, useBytes = TRUE)
  } else if(!is.null(string)) {
    x <- string
  } else {
    stop("either file or string must not be NULL.")
  }
  x <- qserialize(x, preset = "custom", algorithm = "zstd", compress_level = 22)
  x <- base91_encode(x, "'")
  starts <- seq(1,nchar(x), by=width)
  x <- sapply(starts, function(i) {
    substr(x, i, i+width-1)
  })
  x
}

#' Decode a compressed string
#'
#' A helper function for encoding and compressing a file or string to ascii using [base91_encode()] and [qserialize()] with the highest compression level.
#' @usage decode_source(string)
#' @param string The string to decode
#' @return The original (decoded) string.
decode_source <- function(string) {
  x <- paste0(string, collapse = "")
  x <- base91_decode(x)
  qdeserialize(x)
}
