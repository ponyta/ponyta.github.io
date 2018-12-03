---
layout: post
title: Simple Church Numerals
tags: sicp functional recurse
---

# Foreword

I've been working through [Structure and Interpretation of Computer
Programs](http://sarabander.github.io/sicp/html/) lately and recently
went through an interesting exercise on Church numerals. I wanted to share
what I learned, so here is my simplified presentation on them!

# In the beginning, there was only lambda...

Some of the most interesting exercises in SICP involve showcasing how some
primitive language features can be built using nothing but lambdas. To start,
I'm going to introduce some of the basics of Racket itself so that we can build
a primitive system of numbers called Church numerals[^1] on top of it.

At its heart, Racket is a pretty simple language. To call a function `f` with
arguments `a1` and `a2`, simply type `(f a1 a2)`. For example,

```racket
(+ 4 5 (* 2 3))
=> 15
```

This is called prefix notation, since the function name prefixes the arguments.

Also, you can define a variable `x` to some value using the `define` keyword:

```racket
(define x 5)
x
=> 5
```

And define functions by adding a parameter list:

```racket
(define (square x)
  (* x x))
(square 5)
=> 25
```

Finally, the special keyword lambda allows you to build anonymous functions like
so:

```racket
(define square (lambda (x) (* x x)))
(square 2)
=> 4
```

You may notice a similarity between the last two examples. In fact, the two
definitions of `square` are exactly the same; the first is just **syntactic
sugar**[^2] for the second.

When we call any function via parenthesis (for example, `(square 4)`), whatever values
are sent as arguments to the function are substituted in the function body's definition and
simplified. This is called the **substitution model**, and it is a simple way of thinking how a
Lisp interpreter might function. For example, calling `(square 4)` would substitute `4` for `x` in
the body of `square`'s definition. Thus, wherever we would write `x`, we instead write `4` giving
us `(* 4 4)` which is then simplified to `16`.

So with our base set, let us move on to...

# What are numbers, really?

A number system has a lot of properties that we take for granted.[^3] For now, let's
just implement a primitive set of numbers that we can increment and add.

We start with zero and an increment function:[^4]

```racket
(define zero ; i.e. zero is a function with two arguments f and x
  (lambda (f x)
    x)) ; calling this function just returns x

(define (inc n)
  (lambda (f x)
    (f
      (n f x))))
```

To get a better sense of what this number system actually looks like, let's try taking a look at
what actually happens when we apply the increment function using simple substitution:

```racket
(define one (inc zero)) ; evaluating...
=> (define one (inc (lambda (f x) x))) ; substitute value for zero as n in body of inc
=> (define one
    (lambda (f x)
      (f
        ((lambda (f x) x) f x)))) ; simplify internal term ((lambda (f x) x) f x)
=> (define one ; done simplifying.
    (lambda (f x)
      (f x)))
```

So the Church representation for one would be `(lambda (f x) (f x))`. Let's see how two would be
represented:

```racket
(define two (inc one)) ; evaluating...
=> (define two (inc (lambda (f x) (f x)))) ; substitute value for one as n in body of inc
=> (define two
    (lambda (f x)
      (f
        ((lambda (f x) (f x)) f x)))) ; simplify internal term again
=> (define two
    (lambda (f x)
      (f (f x))))
```

Looking at the definitions for one and two, it becomes much clearer what our increment function is
doing. Every time we increment a number, we add another application of `f` to `x`. Thus, the number
`zero` is a function that takes in a function `f` and a value `x`, and applies `f` to `x` exactly
zero times (i.e. it just returns `x`). Similarly, `one` is a function that applies `f` to `x`
exactly once, and `two` applies `f` to `x` twice.

This is actually quite useful, as now we can test our created Church numerals as follows:

```racket
(define (plus1 x) (+ x 1))

(zero plus1 0)
=> 0
(two plus1 0)
=> 2

(define (test-numeral n)
  (n plus1 0))

(test-numeral one)
=> 1
```

# Addition

So how could we define addition? Let's consider first what we want: given two church numerals `a`
and `b`, we need to return a numeral that applies its first argument `f` to its second argument `x`,
`a + b` times.

However, we're in luck! The definition for a Church numeral `a` is a function that applies some
function `a` times (and same for `b`). Thus, we can use this to our advantage by simply passing in
`f`, to `a` and `b` themselves.

```racket
(define (add a b)
  (lambda (f x) ; all Church numerals are functions with two arguments
    (a f ; apply f a times to...
      (b f x)))) ; the application of f to x b times

(define four (add two two))
(test-numeral four)
=> 4 ; it works!
```

# Bonus: Multiplication

Let's try to expand our number system a bit further. Given `a` and `b`, how can we return `a*b`?

If you consider the definition of multiplication, the problem actually becomes
similar to addition. `a*b` is just `a` summed to itself `b` times. Or in other
terms, it's f(x) applied a times, and then doing that process again b times. The
only tricky part is creating a function that calculates `f` applied `a` times.[^5]

```racket
(define (mult a b)
  (lambda (f x) ; again, all Church numerals are functions
    (b ; apply the following function b times:
      (lambda (x)
        (a f x)) ; applies f to x a times
      x)))

(define twelve (mult three four))
(test-numeral twelve)
=> 12 ; horray!
```

# The end

Now that we've designed a basic set of operations for Church numerals, you might want to try
implementing more complicated procedures. Here are a few interesting exercises to try:

1. Can you implement exponentiation? How about even higher-ordered procedures, like Knuth's [up-arrow](https://en.wikipedia.org/wiki/Knuth%27s_up-arrow_notation) operations (tetration, etc.)?
2. Can you generalize operations and write a procedure that returns a general [hyperoperation](https://en.wikipedia.org/wiki/Hyperoperation)? (I.e. `(generate-hyperop 0)` would return the `inc` procedure, `(generate-hyperop 1)` would return `add`.)
3. Can you implement subtraction? (Hint: try implementing the predecessor `pre` function that returns the number that comes before its argument.) This is actually a lot trickier than it looks.

If you are interested in building things out of nothing but functions, then you may want to read up on [Church encoding](https://en.wikipedia.org/wiki/Church_encoding) and [lambda calculus](https://www.inf.fu-berlin.de/lehre/WS03/alpi/lambda.pdf)!

<br />
<hr />
<br />

[^1]: Church numerals were invented by the famous mathematician [Alonzo Church](https://en.wikipedia.org/wiki/Alonzo_Church).

[^2]: Syntactic sugar is just a different syntax that is easier for humans to read or write in. In most cases, defining square in the style of the first example is easier to understand.

[^3]: In this article, we will only consider positive numbers and zero. It is possible to do negative numbers using only lambdas, but it's more complicated.

[^4]: In the book (and I believe most definitions of Church numerals), the functions are [curried](https://en.wikipedia.org/wiki/Currying) (they all have one argument). However, this makes it a little more complicated to understand what's going on, so for the sake of simplicity, these definitions might not be 100% accurate.

[^5]: If we had a curried definition of Church numerals, we actually wouldn't have to define this new anonymous function.
