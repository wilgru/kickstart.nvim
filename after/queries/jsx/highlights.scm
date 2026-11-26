; extends

; Keep component prop assignments grey without changing other operators.
((jsx_attribute
  "=" @punctuation.delimiter)
  (#set! priority 110))
