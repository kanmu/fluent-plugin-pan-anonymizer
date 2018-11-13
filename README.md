# fluent-plugin-pan-anonymizer

A Fluent filter plugin to anonymize records which have PAN (Primary Account Number = Credit card number). The plugin validates PAN using [Luhn algorithm](https://en.wikipedia.org/wiki/Luhn_algorithm) after matching.

Inspired by [fluent-plugin-anonymizer](https://github.com/y-ken/fluent-plugin-anonymizer).

# Requirements

- fluentd: v0.14.x
- Ruby: 2.4

# Installation

```
gem install fluent-plugin-pan-anonymizer
```

# Configuration

NOTE: Card numbers in the example don't exist in the world.

```
<source>
  @type dummy
  tag dummy
  dummy [
    {"time": 12345678901234567, "subject": "xxxxxx", "user_inquiry": "hi, my card number is 4019249331712145 !"},
    {"time": 12345678901234568, "subject": "xxxxxx", "user_inquiry": "hello inquiry code is 4567890123456789"},
    {"time": 12345678901234569, "subject": "I am 4019 2493 3171 2145", "user_inquiry": "4019-2493-3171-2145 is my number"},
    {"time": 14019249331712145, "subject": "ユーザーです", "user_inquiry": "４０１９２４９３３１７１２１４５ のカードを使っています"}
  ]
</source>

<filter **>
  @type pan_anonymizer
  ignore_keys time
  <pan>
    formats /4\d{15}/, /４[０-９]{15}/
    checksum_algorithm luhn
    mask 9999999999999999
  </pan>
  <pan>
    formats /4\d{3}-\d{4}-\d{4}-\d{4}/, /4\d{3}\s*\d{4}\s*\d{4}\s*\d{4}/
    checksum_algorithm luhn
    mask xxxx-xxxx-xxxx-xxxx
  </pan>
</filter>

<match **>
  @type stdout
</match>
```

## The result of the example given above

```
2018-11-13 22:01:35.074963000 +0900 dummy: {"time":12345678901234567,"subject":"xxxxxx","user_inquiry":"hi, my card number is 9999999999999999 !"}
2018-11-13 22:01:36.001053000 +0900 dummy: {"time":12345678901234568,"subject":"xxxxxx","user_inquiry":"hello inquiry code is 4567890123456789"}
2018-11-13 22:01:37.021032000 +0900 dummy: {"time":12345678901234569,"subject":"I am xxxx-xxxx-xxxx-xxxx","user_inquiry":"xxxx-xxxx-xxxx-xxxx is my number"}
2018-11-13 22:01:38.050578000 +0900 dummy: {"time":14019249331712145,"subject":"ユーザーです","user_inquiry":"9999999999999999 のカードを使っています"}
```

Card numbers were masked with given configuration except `time` key and `4567890123456789` in "hello inquiry code is 4567890123456789". `4567890123456789` is not a valid card number.

# License

Apache License, Version 2.0
