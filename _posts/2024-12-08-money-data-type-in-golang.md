---
layout: post
title: "Money Data Type in Golang"
date: "2024-12-08 00:00:00"
category: ""
image: "/assets/images/2024-12-08-money-data-type-in-golang.webp"
feature_image: true
description: ""
keywords:
  - 
  - 
comments: true
archived: true
---

It's a common knowledge that using `Float` (or `Number` in JavaScript, it is `Float64` behind the scene) to store monetary data is a bad idea. If you don't know this yet, try doing `10 / 3` in your choice of programming language. I've seen a lot of LinkedIn post ridiculing JavaScript for this.

![Dividing 10 by 3](/assets/others/floating-point-error-1.webp)

When dealing with user's balance, let's say in US Dollar, we sometimes need to deal with cent value. If a user have a balance of US$10.00 and we want to charge them 50 cent (US$0.50), they will have US$9.50 by the end of it. Doesn't look wrong, right?

But what if the user only has US$1.00 and we charge them 70 cent (US$0.70)? 

![Subtracting 0.70 from 1.00](/assets/others/floating-point-error-2.webp)

Mentally we already done the calculation and got US$0.30, but again when I tried the code in JavaScript, I got `0.30000000000000004`. Now the customer has more money than they should have.

> Huh, weird?
>
> That couldn't be right. Curse you JavaScript!

I mean, this problem can be found not only in JavaScript, but also in all programming language that uses [IEEE 754](https://en.wikipedia.org/wiki/IEEE_754) standard. So Golang has this problem too, run [this piece of code](https://go.dev/play/p/WE25YQNwOZ5) if you don't believe me.

## Dealing with Decimal Place

> So what should we use, then?

Worry not! We have other data type.

Throughout my career, I've seen there are 2 way most developers handle this; either by using `Integer` or `String`.

When using `Integer`, we write US$1 as `100`. Notice that there is no comma separator on the value. This way every calculation can be done in `Integer`, no more floating point issue. This way, we will show `100` in API request/response and database to denote US$1.

When using `String`, we write US$1 as `"1.00"`, then we parse it to `Integer` so we get a value like the previous example, do some calculation, and make it into `String` again to be stored in the database. This way we can show `"1.00"` in the API request/response while calculating them fully in `Integer`.

To be honest, I am a bit opinionated on this money-data-type approach.

I think the `Integer` approach is great since there is no extra step necessary for parsing value, but the downside is the API consumer has to be aware that `100` means `US$1` and not `US$100`.

If you worked in backend, you know how silly it is to trust that the API consumer would have the same thought process as the API developer.

Personally, I liked the second approach where the API consumer can just pass `String` value of either `"1"` or `"1.00"` and we would still get the same `Integer` value of `100` to handle. But, I would store them as `Integer` not `String` so that parsing only happened when receiving request or before sending response.

## Enter the JSON Interface

I would use JSON for most of my API, this is the format most consumer expect to get.

In Go, there are JSON interface methods that we can override to customize the behaviour when receiving request and sending response. We will use this to eliminate the need to manually call the `String` to `Integer` parsing method everytime.

### Determining The Number of Decimal Place

Before we start, let's talk a little bit about currency.

Most countrie uses 2 decimal places. There's country like Kuwait that uses 3 decimal places. And there are countries like Indonesia and Japan that use no decimal place at all. I havn't found any country that use more than 3 decimal places, yet.

Being ambitious, let's say we want to support all currency from every country in the world. Standardizing 3 decimal place on the backend would be great, on the frontend we don't need to care; `"1"`, `"1.0"`, `"1.00"` or `"1.000"` will all be treated as `"1.000"`. Less stress for the API consumers, less conflict we will have. LOL!

### Overriding JSON Marshal/Unmarshal

Now that we have agreed to use 3 decimal places for all money data, let's start by coding the implementation.

This is our starting point, just like all other Go Project:

```go
package main

import (
	"fmt"
)

func main() {
	fmt.Println("Hello, World!")
}
```

First, let's create a custom data type:

```go
type Money int64
```

Notice that we didn't write it as `type Money = int64`, because this is Type Definition, not Type Alias.

The difference is when doing Aliasing, both data type are interchangeable, meaning we can pass `int64` to functions that expect `Money` if it were alias of `int64`. But, in Type Definition, we need to explicitly cast `int64` to `Money` before we can pass it to functions that expect `Money`.

Now that we have our custom data type, let's add 2 methods to change the way we receive JSON request and send JSON response:

```go
// UnmarshalJSON implements the json.Unmarshaler interface
func (m *Money) UnmarshalJSON(data []byte) error {
	// remove quotes from string
	s := strings.Trim(string(data), "\"")

	// if negative, remove sign
	isNegative := strings.HasPrefix(s, "-")
	if isNegative {
		s = s[1:]
	}

	// split by point
	parts := strings.Split(s, ".")
	if len(parts) > 2 {
		return fmt.Errorf("invalid decimal format: %s", s)
	}

	// parse leading part
	intPart, err := strconv.ParseInt(parts[0], 10, 64)
	if err != nil {
		return fmt.Errorf("invalid integer part: %v", err)
	}

	// multiply by 1000, later will add the trailing part
	result := intPart * 1000

	// parse trailing part, only if exist
	if len(parts) == 2 {
		// trim to at max 3 digits (additional decimal places will be ignored)
		decimalPart := parts[1]
		if len(decimalPart) > 3 {
			decimalPart = decimalPart[:3]
		}

		// pad with additional zeros (if less than 3 decimal places)
		for len(decimalPart) < 3 {
			decimalPart += "0"
		}

		// parse
		decimal, err := strconv.ParseInt(decimalPart, 10, 64)
		if err != nil {
			return fmt.Errorf("invalid decimal part: %v", err)
		}

		// combine leading and trailing part
		result += decimal
	}

	// if negative, return back sign
	if isNegative {
		result = -result
	}

	*m = Money(result)

	return nil
}

// MarshalJSON implements the json.Marshaler interface
func (m Money) MarshalJSON() ([]byte, error) {
	// get non-negative value
	value := int64(m)
	sign := ""
	if value < 0 {
		sign = "-"
		value = -value
	}

	// calculate leading and trailing digits
	intPart := value / 1000
	decPart := value % 1000

	// always format to trailing 3 decimal
	str := fmt.Sprintf("%s%d.%03d", sign, intPart, decPart)

	return json.Marshal(str)
}
```

For request/response simulation, we will need a struct that has `Money` data type as the property:
```go
type Data struct {
	Value Money `json:"value"`
}
```

Now to simulate receiving request:
```go
// receiving request
incoming := `{"value": "1"}`

var received Data
_ = json.Unmarshal([]byte(incoming), &received)

fmt.Println("incoming data parsed as int64:", received)
```

The result will look like this:
```sh
incoming data parsed as int64: {1000}
```

What ever value being sent, be it `"1"`, `"1.0"`, `"1.00"` or `"1.000"`, the backend will receive it as `1000`. Neat, huh?

Now to simulate sending response:
```go
// sending response
outgoing := Data{Value: 5000}
sent, _ := json.Marshal(outgoing)

fmt.Println("outgoing data converted to string:", string(sent))
```

The result will look like this:
```sh
outgoing data converted to string: {"value":"5.000"}
```

The `Money` data type will be automatically converted to string. Perfect!

### Putting Them Up

The final result should looks like this:
```go
package main

import (
	"encoding/json"
	"fmt"
	"strconv"
	"strings"
)

type Money int64

func (m *Money) UnmarshalJSON(data []byte) error {
	// remove quotes from string
	s := strings.Trim(string(data), "\"")

	// if negative, remove sign
	isNegative := strings.HasPrefix(s, "-")
	if isNegative {
		s = s[1:]
	}

	// split by point
	parts := strings.Split(s, ".")
	if len(parts) > 2 {
		return fmt.Errorf("invalid decimal format: %s", s)
	}

	// parse leading part
	intPart, err := strconv.ParseInt(parts[0], 10, 64)
	if err != nil {
		return fmt.Errorf("invalid integer part: %v", err)
	}

	// multiply by 1000, later will add the trailing part
	result := intPart * 1000

	// parse trailing part, only if exist
	if len(parts) == 2 {
		// trim to at max 3 digits (additional decimal places will be ignored)
		decimalPart := parts[1]
		if len(decimalPart) > 3 {
			decimalPart = decimalPart[:3]
		}

		// pad with additional zeros (if less than 3 decimal places)
		for len(decimalPart) < 3 {
			decimalPart += "0"
		}

		// parse
		decimal, err := strconv.ParseInt(decimalPart, 10, 64)
		if err != nil {
			return fmt.Errorf("invalid decimal part: %v", err)
		}

		// combine leading and trailing part
		result += decimal
	}

	// if negative, return back sign
	if isNegative {
		result = -result
	}

	*m = Money(result)

	return nil
}

// MarshalJSON implements the json.Marshaler interface
func (m Money) MarshalJSON() ([]byte, error) {
	// get non-negative value
	value := int64(m)
	sign := ""
	if value < 0 {
		sign = "-"
		value = -value
	}

	// calculate leading and trailing digits
	intPart := value / 1000
	decPart := value % 1000

	// always format to trailing 3 decimal
	str := fmt.Sprintf("%s%d.%03d", sign, intPart, decPart)

	return json.Marshal(str)
}

type Data struct {
	Value Money `json:"value"`
}

func main() {
	// receiving request
	incoming := `{"value": "1"}`

	var received Data
	_ = json.Unmarshal([]byte(incoming), &received)

	fmt.Println("incoming data parsed as int64:", received)

	// sending response
	outgoing := Data{Value: 5000}
	sent, _ := json.Marshal(outgoing)

	fmt.Println("outgoing data converted to string:", string(sent))
}
```

## Closing Up

Now you know (arguably) the best way to handle money data in Golang.

Joke aside, this approach is not the perfect (yet), for production you might want to add more handling such as arithmetic operations, validation rules, and formatting with currency.

But, so far, using this approach, you already get:
- Consistent decimal places handling
- Clean API request/response with string representation
- No floating-point arithmetic errors

I'd say that's already enough for a starter ＼(٥⁀▽⁀ )／