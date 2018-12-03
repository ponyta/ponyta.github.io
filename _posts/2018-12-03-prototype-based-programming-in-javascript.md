---
layout: post
title: Prototype-based programming in Javascript
tags: javascript
---

*How to make a cat bark in Javascript*

# What does prototype-based programming mean?

Javascript (like many modern languages) supports object-oriented programmming. However, while most people are used to a class-bassed
implementation, where objects are created from a set of blueprints called a **class**, Javascript implements a different model
called **prototype-based** programming (also known as classless, or instance based programming). Characteristically of
Javascript, a prototype-based model gives us a powerful, but also confusing and dangerous paradigm.

**Note**: If you would like to try the examples in this post, they have been tested on
Google Chrome. They may work in other Javscript environments, but it is not guarenteed.

# What is an object?

Javascript objects are quite simple; you can think of them as just a list of key-value pairs.
We call the keys **properties**. When you call an object with some key you want, Javascript searches
the list of properties for the appropriately matching string key and returns it.

This is probably best illustrated with an example:

```javascript
var frank = {
    'species': 'turtle', // i am a turtle
    'canSwim': true, // yes they can!
    'talk': function() {
        return "eeeee"; // the sound turtles make
    }
};

// we can access an objects properties with bracket notation
frank['species']; // => "turtle"
// or dot notation
frank.canSwim; // => true
// we can even call functions that are property values
frank.talk(); // => "eeeee"
```

{% capture note0 %}
Object properties are always strings. Javascript will implicitly convert properties you give it to strings.
Try running the following and see how many keys these objects have:

```javascript
var x = {
    '5': 'val1',
    5: 'val2'
}

var y = {
    true: 'oh this is bad',
    'true': 'Im sure this wont cause any bugs in production'
}
```

Values however, can be any type.
{% endcapture %}
{% include note.html content=note0 %}

However, objects can have more properties than what you explicitly define on them. For example, consider:

```javascript
// where did this function come from?
frank.toString(); // => "[object Object]"
```

This is because of something called the **prototype chain**.

# The prototype chain

If you ask an object for a property and Javascript can't find it defined on the object itself, it will travel
up the object's prototype chain looking for the property. If it hits the end and doesn't find it, it returns an
error.

You can view an object's prototype by using the `Object.getPrototypeOf` method on an object. For example, let's
look at what `frank`'s prototype has:

```javascript
Object.getPrototypeOf(frank);
// an object is printed out
// {
//   constructor: f Object()...
//   toString: f toString() .... // hey that's our toString property!:
//   ....
// }
```

{% capture note3 %}
Most implementations of Javascript will also expose an object's prototype with the `.__proto__` property, which is
similar to `setPrototypeOf` and `getPrototypeOf`. However, this was not meant to be in the specification, and is
not guarenteed to work. Also, keep in mind that using either `.__proto__` or `setPrototypeOf` has subtle performance
effects, and is not recommended.
{% endcapture %}
{% include note.html content=note3 %}

You'll find that `toString` method that we were wondering about before!

It's also important to know that if Javascript can't find the property in the prototype of the object you were looking
at, it continues looking at the prototype's prototype, and so on until there are no more prototypes.

{% capture note4 %}
You might wonder what is at the end of the prototype chain. The root of the prototype chain is called `Object.prototype`
(we'll see why later). And since `Object.prototype` is always at the end of the prototype chain, its prototype is `null`.

Try the following code out yourself:

```javascript
var rootProto = Object.getPrototypeOf({})
rootProto == Object.prototype // => true
Object.getPrototypeOf(rootProto); // => null
```
{% endcapture %}
{% include note.html content=note4 %}

We can even modify this prototype like any other object, giving all objects with it in its chain new properties:

```javascript
var objProto = Object.getPrototypeOf(frank);
objProto.hello = function() {
    return "hello world!";
}
var someOtherObj = { test: 'foo' };
someOtherObj.hello(); // "hello world!"
```

Although modifying widely used prototypes such as Object's or Array's is probably bad engineering practice.

But where did this prototype come from? Well it turns out that whenever we create an object with the
`{}` syntax, the interpreter automatically assigns it the Object prototype. However, we don't always want objects
with an Object prototype, which leads us to...

# The new keyword
Another way to create new objects in Javascript is by utilizing the `new` keyword
with a function as a constructor. Before we get into actually constructing objects though, let's address the problem of
actually creating a new prototype in the first place.

It turns out that Javascript automatically creates prototypes whenever you define a new function. Every function has a
`prototype` property that is created by the interpreter, and acts as a new empty prototype who's prototype is `Object.prototype`.
This prototype is assigned to any object created using this function as a constructor.

{% capture note5 %}
A function's `prototype` property is not to be confused as the function object itself's prototype. A function is an object, and its
prototype can be accessed via `Object.getPrototypeOf`, like any other object.

If you don't believe me, try the following code:

```javascript
function Foo() { }
Foo.prototype == Object.getPrototypeOf(Foo); // false
// actually, Foo's prototype is Function.prototype
Object.getPrototypeOf(Foo) == Function.prototype; // true
```

This is a pretty big source of confusion since I'll often state things like "an object's prototype". This always refers to the value
`Object.getPrototypeOf(obj)`, and not `obj.prototype`. In other words, an object's prototype is not the prototype property on an object
(which is usually undefined for non-functions).
{% endcapture %}
{% include note.html content=note5 %}

Now let's take a look at an example:

```javascript
// functions for use as a constructor start with a capital
// by convention.
function Horse(color, rider) {
    this.color = color;
    this.rider = rider;
}

var redHare = new Horse('red', 'Guan Yu');
```

The first thing you might ask is what `this` is. In Javascript, when you call a function
with the `new` keyword, a few things happen:

1. A new object gets created with its prototype set to the constructor function's prototype property
2. The `this` keyword is set to point to the new object
3. If the constructor does not return anything, or returns a non-object then `this` is returned
instead by default. Otherwise, the expression returns the object returned by the constructor

{% capture note1 %}
It is possible to return an object other than `this` from your constructor.
For example, you may want to return a singleton instance instead, like so:

```javascript
Person.elvis = {
    'name': 'Elvis',
    'description': 'The one, the only...'
};

function Person() {
    return Person.elvis;
}
```

Although whether or not this is a good idea is up to you.
{% endcapture %}
{% include note.html content=note1 %}
{% capture note2 %}
If you don't call a function with the `new` keyword, then the `this` keyword is never set. By default,
it is set to the global object (the `window` object in most browsers) which may lead to bugs if you call
a function meant to be a constructor without the `new` keyword.
{% endcapture %}
{% include note.html content=note2 %}

With our new object and prototype in hand, we can start to do all sorts of new, cool things:

```javascript
Horse.prototype.speak = function() {
    return "neigh";
}

Horse.prototype.isFast = true; // it's true

redHare.speak(); // neigh
redHare.isFast; // he is a fast one
```

However, one limitation you might notice with `new` is that the interpreter always sets the newly created prototype with
`Object.prototype` as it's parent prototype. If we want to create longer, more complicated prototype chains, we're going to
have to find a third way of creating objects.

# Object.create

`Object.create` is probably actually the simplist way to create an object with an explicit prototype; it takes a prototype
as a parameter and returns a new object with its prototype set to the parameter passed in. For example:

```javascript
function Dog() { } // let the interpreter create a new prototype object
Dog.prototype.speak = function() {
    return "woof";
}
Dog.prototype.isCute = true; // of course, dogs are cute

var snoopy = Object.create(Dog.prototype); // create using Dog's prototype
snoopy.speak(); // => woof
Object.getPrototypeOf(snoopy) === Dog.prototype // true
```

Keep in mind we can pass whatever object we want as the prototype - whether it's a prototype automatically created by
the definition of a function, or a completely new object we construct ourselves.

# this

It's important also to understand how the `this` keyword operates in Javascript. `this` is a pointer the interpreter sets
based on the current context:

1. In general, in a global context `this` points to the global object (`window` in most browsers).
2. As we've already seen, if a function is called via the `new` keyword, `this` refers to the newly created object in the
constructor's context.
3. When a function is called on an object, `this` refers to the object in the function's context. For example, if
`dog.speak()` was called, `this` would refer to `dog` while the `speak` function is executing.
4. Finally, you can set the value of `this` by using the special function `foo.call(context, arg1, arg2, ..., argn)`, which
calls `foo` with arguments `arg1`, `arg2`, ..., `argn` and sets `this` to `context` while it is executing.

(For a complete summary of all cases, always refer to documentation such as
[MDN](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/this))

{% capture note8 %}
Javascript has introduced a new way of defining functions using the `=>` syntax called
[**arrow functions**](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Functions/Arrow_functions).
A lot of the behaviour discussed here does not apply to these, and you should read the documentation
for more information (for example, arrow functions don't rebind the `this` keyword, and they do not have a `prototype`
property for usage as a constructor).
{% endcapture %}
{% include note.html content=note8 %}

# The constructor property

There's one final minor property worth talking about just to iron out all the details, and that's the `constructor` property. When I said that
Javascript automatically creates an empty prototype for every function, I slightly lied. In fact, all prototypes created by Javascript
automatically define one property called `constructor`, whose value is the function used to construct the object the prototype is attached to.

To illustrate this with an example, let's look at this bit of code:

```javascript
// true, the Object prototype seems to hold this property.
Object.prototype.constructor === Object;

// a new constructor
function Monkey() {}
// just to illustrate, Javascript creates a prototype
// for Dog for use with the new keyword
var wuKong= new Monkey();
// also true for prototypes automatically created by Javascript
Object.getPrototypeOf(wuKong).constructor === Monkey;

// what about Object.create?
var george = Object.create(Monkey.prototype);
// also true; the prototype reused so this shouldn't be a surprise.
Object.getPrototypeOf(george).constructor === Monkey;

// consider this second illustration for Object.create
var myProto = {}; // making my own custom prototype
var foo = Object.create(myProto);
// we travel up the prototype chain myProto -> Object.prototype,
// finding the constructor property
foo.constructor === Object;
```

The `constructor` property is used in the `instanceof` keyword. More specifically, `object instanceof constructor` returns true if and only if
`object` has `constructor.prototype` in its prototype chain.

Overall, it's probably best to have constructor of a prototype set to the proper value, just to be safe.

# Inheritance

Now that we have all our ducks in a row, we're ready to implement some class-like inheritance! The goal for now
is to implement a base `Animal` constructor, and then a `Cat` constructor. Objects created by `Cat` should
inherit any behaviour `Animal` objects have via the prototype chain.

Let's start with `Animal`. Objects of type `Animal` should have a simple prototype chain of just `Animal.prototype`
-> `Object.prototype` -> `null`.

```javascript
// our constructor function
function Animal(color) {
    this.color = color;
}
Animal.prototype.describe = function() {
    // When a function call is of the form obj.foo(),
    // this is set to the value obj.
    return "I am a " + this.constructor.name + " of color " + this.color;
}
Animal.prototype.walk = function() {
    return "Doing some walking...";
}

var myAnimal = new Animal('green');
myAnimal.describe(); // "I am a Animal of color green"
myAnimal.walk(); // "Doing some walking..."
myAnimal instanceof Animal; // true
```

Next, we will create the `Cat` prototype to inherit from `Animal.prototype`. That is, we want a prototype chain of
`Cat.prototype` -> `Animal.prototype` -> `Object.prototype` -> `null`.

```javascript
// first let's just create a Cat constructor and prototype
function Cat(breed, color) {
    // call the super constructor, but make sure you rebind
    // this so we modify the correct object!
    Animal.call(this, color);
    // continue as normal
    this.breed = breed;
}
// Now we have to fix the prototype of Cat. Remember the
// interpreter automatically sets Cat.prototype to Object.prototype!
// We can fix this by creating our own prototype object.
Cat.prototype = Object.create(Animal.prototype);
// But we have to manually set the constructor property since
// the new prototype is an empty object
Cat.prototype.constructor = Cat;
// Now we can define methods on our prototype as normal
Cat.prototype.speak = function() {
    return "meow";
}
// We can also override methods! Remember this works because
// Cat's prototype comes before Animal's in the chain
Cat.prototype.walk = function() {
    return "I prefer to prowl...";
}
var pistachio = new Cat('moggy', 'black');
pistachio.speak(); // meow
pistachio.walk(); // I prefer to prowl...
// Even describe properly updates, since it references "this"
pistachio.describe(); // I am a Cat of color black

// and instanceof works as expected
pistachio instanceof Cat; // true
pistachio instanceof Animal; // true
// just for sanity...
myAnimal instanceof Cat; // false
```

# Accessing the prototype

We've learned how to manipulate prototypes and the prototype chain, but we *haven't* seen how to change an object's
prototype once it has already been created. This is actually possible using a special function called
`Object.setPrototypeOf(obj, prototype)`. However, it is strongly recommended to **never do this**. Javascript engines
implement many optimizations to speed up property access, and allowing dynamic updates to an object's prototype can
severly affect these optimizations in subtle ways beyond what you might expect.

Regardless, we're already here so let's try turning our cat into a dog:

```javascript
pistachio.speak(); // meow
Object.setPrototypeOf(pistachio, Dog.prototype);
// I'm still a black moggy!
pistachio.color; // black
pistachio.breed; // moggy
// But my behaviour has changed...
pistachio.speak(); // woof?!?!
pistachio instanceof Dog; // true
```

Although if you know [cats](https://www.youtube.com/watch?v=aP3gzee1cps) you might not be too surprised by this...

# Overview
Are you confused? Don't worry, you're not alone. Here's a high level overview of everything:

- When Javascript tries to access an object's property, it first looks at the object directly, then the object's prototype, then that prototype's prototype, and so on until it hits `null`. This is called the **prototype chain**.
- You can view an object's prototype using the `Object.getPrototypeOf(obj)` function.
- Every function has a `prototype` property, which represents the prototype assigned to objects created using that function as a constructor (even if it is never used as a constructor).
- A function `foo` also has a prototype, which is not `foo.prototype`, but rather `Object.getPrototypeOf(foo)`, and is equivilant to `Function.prototype` (functions are also objects).
- We have covered three main ways to create objects:
    - Using the `{}` syntax, which creates a new object with the `Object.prototype` prototype.
    - Using the `new foo()` syntax, which creates a new object, sets its prototype to `foo.prototype`, and runs `foo` with the `this` keyword set to the newly created object.
    - Using `Object.create(<prototype>)`, which returns a new object with its prototype set to the `<prototype>` object you passed in.
- Prototypes automatically provided by the interpreter are given a `constructor` property which should point to the function
that constructed the object the prototype is attached to.
- The `this` keyword can be set in four main ways:
    - When executing normally, `this` is the global object (`window`).
    - When executing `new foo()`, `this` is set to the newly constructed object.
    - When executing `obj.foo()`, `this` is set to point to `obj`.
    - When executing `foo.call(context, args...)`, `this` is set to point to `context`.
- We can use a combination of the above behaviour to implement class-like inheritance. For example, say we want `Child`
to inherit from `Parent`:
    - Implement a `Child()` constructor with an empty prototype
    - In the constructor, call the super constructor `Parent()` if needed, properly setting the `this` keyword via
    `Parent.call(this, args...)`.
    - Set up the prototype chain for `Child` by making `Child.prototype = Object.create(Parent.prototype)`.
    - Assign the correct constructor property to the `Child` prototype via `Child.prototype.constructor = Child`.

If you think you got it, try implementing these problems to test your knowledge:

1. Change `Dog` to properly create objects that inherit from `Animal`.
2. Implement an equivalent to static methods, like an `Animal.randomAnimal()` method that generates a new `Animal` with
random property values. What is the value of `this` when calling this method?
3. Implement an equivalent to static fields, like a `Cat.BREEDS` field that stores all `Cat` breeds. Make sure it behaves
the same way as a class-based implementation would.

# Exercises
If you like being mindblown (or just confused with Javascript), try and guess what these code snippets do, and then run them!
If you're brave you can take a shot every time you get one wrong, but I'm not responsible for any alcohol related deaths.

Don't feel bad if you don't get them, as some of these are nearly impossible to know unless you know the ECMAScript specification inside and out. They are also not all directly related to prototype-based programming.

*Snippets tested in Google Chrome.*

1. ```javascript
   // what is this?
   let mystr = "asdf";
   let otherstr = new String("blup");
   String.prototype.myself = function() {
       return this;
   }
   typeof mystr; // ??
   typeof otherstr; // ??
   typeof mystr.myself(); // ??
   typeof otherstr.myself(); // ??
   ```

2. True or false: the only object in Javascript with a `null` prototype is `Object.prototype` (note: `null` is not an object,
despite what `typeof null` outputs, as it is a primitive data type. In fact, if you want proof `typeof` is not the greatest,
try typing in `typeof NaN`).

3. ```javascript
   typeof String.prototype // ??
   typeof Object.prototype // ??
   ```

4. ```javascript
   1 instanceof Number // ??
   true instanceof Boolean // ??
   [] instanceof Array // ??
   "who am i?" instanceof String // ??
   new String("none of your business") instanceof String // ??
   ```

# Final
Although prototype-based programming is interesting and powerful, from an engineering perspective it may be overly
complicated and dangerous. There is a new `class` keyword coming in JavaScript that seems to abstract a lot of the
troubles, and probably covers most engineer's usecases. I would probably recommend looking at that for practical purposes.

Also, I didn't really go into what makes prototype-based programming so especially powerful. The main reason is that because
objects inherit directly from other objects, prototype-based languages allow you to easily alter prototypes at runtime. In
contrast with class-based programming, this is much more difficult or even impossible. However, you could also make the
argument that allowing dynamic behavioural changes is dangerous and unpredictable. I have already demonstrated that
class-like behaviour can be emulated in a prototype-based environment, but the reverse is not true. The class-based paradigm
is a strict subset, and hence strictly weaker version of the prototype-based paradigm.

Finally, I was careful to try and make sure I only made true statements in this post. If you find something you think is
wrong, feel free to send me an email to correct it! Prototypes can be complicated, and Javascript is a messy language. If
possible, a code example illustrating your point would be helpful.
