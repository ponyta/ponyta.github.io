---
layout: post 
title: Adventures in Lambda Calculus 
tags: sicp functional recurse 
math: true
---

This blog post is a written up extension of work I did while reading SICP. You can look at the original file
[here](https://git.chunli.me/sicp.git/tree/lambda.rkt). It is also an extension of the [Simple Church
Numerals](https://blog.chunli.me/2018/10/06/simple-church-numerals.html) post. I would also like to acknowledge [*"A
Tutorial Introduction to the Lambda Calculus"*](https://www.inf.fu-berlin.de/lehre/WS03/alpi/lambda.pdf) and
[*"Recursion in the Lambda Calculus"*](http://www.cs.toronto.edu/~david/courses/csc324_w15/extra/ycomb.html) as
extremely helpful resources.

# Introduction

I started out exploring lambda calculus with a simple question: how much functionality of a "standard" programming
language can I implement using only functions and a simple substition machine? Introductory computer science courses are
often filled with explanations of language keywords: `if` statements, `for` loops and so on. But we've already seen in a
[previous blog post](https://blog.chunli.me/2018/10/06/simple-church-numerals.html) as well as SICP that some of this
functionality is not really new; that it can be thought of as simple syntactic sugar for a series of lambda function
applications.

Thus my goal was to implement as much of the standard functionality of Racket I learned using only lambda calculus.
Although most of the work was done via mathematical notation (on pen and paper), I will be showcasing the Racket
implementation of that work.

# The Rules of Lambda Calculus

Lambda calculus at it's core is a very simple programming language. It consists of evaluating expressions, which are
defined as follows:

**Definition**: An *expression* is either a *name*, a *function*, or an *application*.

**Definition**: A *name*, or *variable* is any identifier. For simplicity, we will use lowercase letters, such as a, or
x.

**Definition**: A *function* consists of the following form: \\(\lambda\\) <\\(‌name\\)>.<\\(expression\\)>. The name
before the period is the parameter of the function, and the expression after the period is the body. For example,
\\(\lambda x.x\\) is the identity function.

**Definition**: An *application* consists of the following form: \\(expression‌ ‌‌expression\\). If the first expression
is a function, we can substitute the parameter for the second expression in the function body. For example, \\( (\lambda
x.x)y \\) would apply y to the identity function, resulting in y. This substitution is also known as a
\\(\beta\\)-reduction.

In Racket we can express names as any symbol, functions as `(lambda (<name>) <expression>)`, and an application as
`(<expression> <expression>)`. As you can see, lambda calculus itself is not much more than a simple substitution
machine.

It's important to note that the actual symbol used for a name does not matter. That is, \\(\lambda x.x\\) and \\(\lambda
y.y\\) both represent the same function (this is called \\(\alpha\\)-equivalence). This is important however, if you are
substituting in an expression containing symbols already being used in the body. For example, consider the following
substitution:

$$ (\lambda x.(\lambda y.xy))y \Rightarrow \lambda y.yy$$

But this is incorrect since the y substituted in is different from the y inside the function body. If we had used a
different variable name, such as t we would have gotten a different result, like so:

$$ (\lambda x.(\lambda t.xt))y \Rightarrow yt $$

which is actually correct. It is important to avoid name collisions by renaming variables when necessary while doing
substitution to get the correct answer.

{% capture note0 %}
I've glossed over some of these details rather quickly. If you would like a more formal definition of
\\(\alpha\\)-equivalence, \\(\beta\\)-reduction, and the importance between *bound* and *free* variables, I suggest
reading one of the resources cited at the beginning of the article.
{% endcapture %} 
{% include note.html content=note0 %}

Another important note is that there are no named functions. All functions are anonymous in lambda calculus: to call a
function, we write out the body and call it's parameters. For the sake of convenience we will allow our functions to
have aliases by using Racket's `define` keyword.

Finally, one small limitation you might see is that our functions currently only take one variable. It is relatively
simple to see that a multi-parameter function can be represented by nested uni-parameter functions. For example, if we
wanted some function that took 3 parameters x, y, and z, then we could represent that as a function with parameter x
that returned a function that takes in a parameter y, which then returns a function that takes in some parameter z,
which then runs the function body with the 3 parameters.

In other words, in lambda calculus:

$$\lambda xyz.xyz \Leftrightarrow \lambda x.(\lambda y.(\lambda z.xyz))$$

Or, in Racket:

```racket
(lambda (x y z) <body>) <=> (lambda (x) (lambda (y) (lambda (z) <body>)))
```

This process of transforming a multi-parameter function is also called
[currying](https://en.wikipedia.org/wiki/Currying). I won't formally go through it but hopefully it is relatively clear
that multi-parameter functions can easily be represented in our system. I will use curried and non-curried functions
throughout this post based on what is more convenient and clear.

# Building the Language

Now that we understand the basics of lambda calculus, let's start seeing what it can do. Our goal is to utilize only
lambdas and the simple substitution model of Racket to build as many language features as we can.

**1. Church Numerals**

[We've already seen](https://blog.chunli.me/2018/10/06/simple-church-numerals.html) a system capable of representing
numbers. For a full explanation, please see my previous blog post, as I will be glossing over most of the explanation
here.

Let us first define zero, as well as a successor function:

``` racket
(define zero
  (lambda (f)
    (lambda (x)
      x)))

(define suc
  (lambda (n)
    (lambda (f)
      (lambda (x)
        (f ((n f) x))))))
```

We can then represent the set of positive integers. For example:

```racket
(define one (suc zero))
(define two (suc one))
(define three (suc two))
(define four (suc three))
(define five (suc four))
```

Noting that a Church Numeral n is a function that applies it's first argument n times on it's second argument, we can
also form the functions addition and multiplication:

```racket
(define add
  (lambda (a b)
    ((a suc) b)))

(define mult
  (lambda (a b)
    (lambda (f)
      (a (b f)))))
```

Unfortunately, since Racket just prints `#<procedure>` instead of an actual expression, we'll need more
testing methods to actually see the value of our Church numeral:

```racket
; We'll test the Church numeral n by applying the increment function to 0 n times.
(define (inc n)
  (+ 1 x))
(define (test-numeral n)
  ((n inc) 0))

(test-numeral (add four three)) ; => 7
(test-numeral (mult four three)) ; => 12
```

**2. Conditionals**

Every language needs some form of if statement. Let's start with booleans:

```racket
; We'll represent booleans as two parameter functions.
; True returns the first argument, false returns the second.
(define TRUE
  (lambda (x)
    (lambda (y)
      x)))

(define FALSE
  (lambda (x)
    (lambda (y)
      y)))
```

Because of our convinient definition, an if statement is just the application of a boolean to the two branches:

```racket
; If pred is TRUE, then we will return the truth expression.
; If pred is FALSE, then we will return the otherwise expression.
(define IF
  (lambda (pred truth otherwise)
    ((pred truth) otherwise)))
```

It would be nice to have some basic boolean operations, like `and`, `or`, and `not`:

```racket
; AND is a function that takes two booleans x and y.
; If x is TRUE, it will return y (thus returning TRUE if y is also TRUE, and 
; FALSE if y is FALSE). Otherwise, x is FALSE, so we should return the function 
; FALSE.
(define AND
  (lambda (x y)
    ((x y) FALSE)))

; Similarly, these 
(define OR
  (lambda (x y)
    ((x TRUE) y)))

(define NOT
  (lambda (x)
    ((x FALSE) TRUE)))
```

Again, we'll need more testing methods to make sure our new boolean logic works:

```racket
(define test-bool
  (lambda (b)
    (IF b "TRUE" "FALSE")))

(IF (OR FALSE
        (AND TRUE
             (NOT FALSE)))
    "recurse"
    "center")
; => "recurse"
```

Let's try connecting the two pieces we've built and write a function that tests if a
numeral is zero:

```racket
(define isZero?
  (lambda (n)
    (((n FALSE) NOT) FALSE)))
```

Or in lambda calculus (where F is false, and T is true):

$$ isZero = \lambda n.nF\neg F $$

Let us see how this function works. Say we substitute in 0:

$$ (\lambda n.nF\neg F)0 \Rightarrow 0F\neg F $$

Remember that 0 is a function that applies it's first argument 0 times to it's second argument (thus just returning the
second argument):

$$ \Rightarrow \neg F \Rightarrow T$$

Thus returning true. Now let's say we substitute any other number, say 2:

$$ (\lambda n.nF\neg F)2 \Rightarrow 2F\neg F $$

2 then applies F to \neg twice:

$$ \Rightarrow (F(F\neg))F $$

It is important to understand the order of function application, which I have emphasised with brackets above. Now since false is
a function that always returns it's second argument and ignores the first, false applied to one argument will always result in the
identity function. More clearly, given \\(F = \lambda xy.y\\), then:

$$ Fz = (\lambda xy.y)z $$

$$ \Rightarrow \lambda y.y $$

Thus, F applied to a single argument will always result in the identity function. Hence,

$$ (F(F\neg))F \Rightarrow (F \lambda x.x)F \Rightarrow (\lambda x.x)F \Rightarrow F $$

It is easy to generalize this and see that F applied any number of times to a single argument always leads to the identity function. Thus
isZero always returns false for non-zero numbers.

**3. Pairs**

Lists are a pretty fundamental structure in Lisp, so we should definitely try to implement them. First, we'll implement the constructor for a pair:

```racket
(define pair ; like cons
  (lambda (a b)
    (lambda (z)
      ((z a) b))))
```

Note that a pair is a function that takes some function and applies it to the two elements in the pair. If we want to
get the first element of the pair, we just need to pass in a function that takes two arguments and returns the first
one, and similarly for the second element. Conviniently, this is the exact behaviour of our booleans true and false:

```racket
(define first ; like car
  (lambda (p)
    (p TRUE))) ; select the first arg
(define rest ; like cdr
  (lambda (p)
    (p FALSE))) ; select the second arg
```

Now with our pair structure, we can write a function that increments a pair of consecutive numbers:

```racket
; increments a pair of number (n, n-1) to (n+1, n)
(define inc-pair
  (lambda (p) ; p is our pair
    (pair (suc (first p))
          (first p))))
```

We can then use this function to keep track of the previous number when incrementing through numbers, thus allowing us to
write the predecessor function:

```racket
; predecessor function
; note one interesting property is that (pre zero) is zero.
(define pre
  (lambda (n)
    (rest 
      ((n inc-pair) ; apply inc-pair n times
        (pair zero zero))))) ; to (0, 0)
```

With the predecessor function, we can finally implement subtraction by applying `pre` multiple times, and thus numerical
comparison. Note that we still cannot represent negative numbers. Since `(pre zero)` is `zero`, any subtraction that would
result in a negative simply evaluates to zero:

```racket
; greater than or equal
(define GTE
  (lambda (x y)
    (isZero? 
      ; is x - y zero?
      ((x pre) y))))

; similarly...
(define LTE
  (lambda (x y)
    (isZero? ((y pre) x))))

(define EQ
  (lambda (x y)
    (AND (GT x y) (LT x y))))

(define GT
  (lambda (x y)
    (AND (GTE x y) (NOT (EQ x y)))))

(define LT
  (lambda (x y)
    (AND (LTE x y) (NOT (EQ x y)))))

(define NEQ
  (lambda (x y)
    (NOT (EQ x y))))
```

**4. Recursion**

One important thing we can't do yet is recursion. Remember that all functions are anonymous; we cannot give them names.
I have only allowed definitions in here for the sake of convinence but a function is not allowed to refer to itself in
it's own body.

Recursion however is still possible! Let us consider the following function:

```racket
(define Y
  (lambda (y)
    ((lambda (x)
       (y (x x)))
     (lambda (x)
       (y (x x))))))
```

Let's just say I apply some argument R to Y. What does the substitution machine do?

```racket
(Y R)

=> ((lambda (x) (R (x x)) (lambda (x) (R (x x))
```

Substituting the second `(lambda (x) (R x x))` as `x` in the first half, we get:

```racket
=> (R ((lambda (x) (R (x x)) (lambda (x) (R (x x))))

=> (R (Y R))
; thus, since we've shown (Y R) evaluates to (R (Y R)), it follows that
...
=> (R (R (Y R)))
=> (R (R (R (Y R))))
; and e.t.c.
```

Let's try this function out. We will write a function that sums all the positive numbers up to n
as follows:

```racket
(define sum-to-n
  (lambda (r) ; r is the 'name' of our recursive function
    (lambda (n) ; n is the parameter we want our function to take in
      (IF (isZero? n) zero
          (add n (r (pre n)))))))
```

Then consider what happens when we evaluate:

```racket
((Y sum-to-n) three)
; since (Y R) becomes (R (Y R)), then
=> ((sum-to-n (Y sum-to-n)) three)
; substituting our two arguments (Y sum-to-n) and three into sum-to-n...
=> (IF (isZero? three) zero
       (add three ((Y sum-to-n) (pre three))))
=> (add three ((Y sum-to-n) (pre three)))
=> (add three ((Y sum-to-n) two))
; and the whole cycle begins again until we end up with
...
=> (add three (add two (add one ((Y sum-to-n) zero))))
=> (add three (add two (add one
     (IF (isZero? zero) zero
         (add zero ((Y sum-to-n) (pre zero)))))))
; take the base case
=> (add three (add two (add one zero)))
...
=> six ; which is correct!
```

Thanks to our helper function Y, we have recursion! In fact, Y is so famous it has its own name:
it's called the Y-combinator, and was created by Haskell Curry.

Unfortunately, if any of you actually were to put this in a Racket interpreter and run it, you'll find that it doesn't actually
work! In fact, the function will just evaluate forever, never terminating. This is because in our informal description,
we actually glossed over a few crucial details.

The first is that we never discussed what order to evaluate things in: should we try to simplify function
arguments first, or substitute arguments into function bodies first? This difference is sometimes called
*normal-ordered* evaluation versus *applicative-ordered* evaluation, or *strict* vs *lazy* evaluation. 
In the above examples, I've chosen the optimal ordering in order to give the proper answer, but Racket
defaults to strict ordering, always attempting to substitute `(Y R)`. This results in
`(Y R) => (R (Y R)) => (R (R (Y R))) => (R (R (R (Y R)))) ...` forever instead.

The second detail is that our implementation of `IF` evaluates both branches; in which case it will
infinitely recurse on the second branch, even if the base case evaluates to true. Most programming languages
will only evaluate code in the branch that gets executed.

To get around this, we are going to tweak our definition of the Y-combinator to work with
strict-order evaluation. Consider the following new definition of the Y-combinator:

```racket
(define Y
  (lambda (t)
    ((lambda (y)
       (t (lambda (x)
                   ((y y) x))))
     (lambda (y)
       (t (lambda (x)
                   ((y y) x)))))))
```

This works similarly, as so:
```racket
(Y R)
=> ((lambda (y)
      (R (lambda (x)
           ((y y) x))))
    (lambda (y)
      (R (lambda (x)
           ((y y) x)))))
=> (R (lambda (x)
        (((lambda (y)
            (R (lambda (x)
                 ((y y) x))))
          (lambda (y)
            (R (lambda (x)
                 ((y y) x))))) x)))
=> (R (lambda (x)
        ((R (lambda (x)
              (((lambda (y)
                  (R (lambda (x)
                       ((y y) x))))
                (lambda (y)
                  (R (lambda (x)
                       ((y y) x)))))
               x))) x)))
=> (R (lambda (x)
       ((R (lambda (x)
             ((R (lambda (x)
                   (((lambda (y)
                      (R (lambda (x)
                           ((y y x)))))
                    (lambda (y)
                      (R (lambda (x)
                           ((y y x)))))) x)))
              x)))
        x)))
...
=> (R (lambda (x)
        ((R (lambda (x)
              ((R (lambda (x)
                    ...
                    ((R (lambda (x)
                          (((lambda (y)
                              (R (lambda (x)
                                   ((y y) x))))
                            (lambda (y)
                              (R (lambda (x)
                                   ((y y) x))))) x)))
                     ...
                     x)))
               x)))
         x)))
```

However, this version works with strict order evaluation. To solve our other problem, we'll have to use Racket's built in `if` statement.
For convenience, we can rewrite `isZero` to return native boolean values:

```racket
(define Z
  (lambda (n)
    (((isZero? n) #t) #f)))
```

And thus write our sum function as follows:
```racket
(define sum-to-n
  (lambda (r)
    (lambda (n)
      (if (Z n) zero
        (add n (r (pre n)))))))
```

We can also write a factorial function just for fun:

```racket
(define factorial
  (lambda (fact)
    (lambda (n)
      (if (Z n) one
        (mult n (fact (pre n)))))))
```

And with that we are able to implement recursion!

# Outro

Even though building functionality already available in Racket using anonymous functions is not a particularly practical exercise, I still find it
interesting and fun. The [Church-Turing thesis](https://en.wikipedia.org/wiki/Church%E2%80%93Turing_thesis) implies that lambda calculus is capable 
of computing anything a Turing machine can, and so it should be possible to implement any language feature using lambda calculus. Although this post
is more informal and exploratory than anything, I hope it is a good introduction to the world of lambda calculus.