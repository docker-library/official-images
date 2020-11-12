# History

## v3.2.0 2018 December 7

-   Updated [base files](https://github.com/bevry/base) and [editions](https://editions.bevry.me) using [boundation](https://github.com/bevry/boundation)

## v3.1.1 2018 September 3

-   Updated [base files](https://github.com/bevry/base) and [editions](https://editions.bevry.me) using [boundation](https://github.com/bevry/boundation)

## v3.1.0 2018 August 16

-   Updated [base files](https://github.com/bevry/base) and [editions](https://editions.bevry.me) using [boundation](https://github.com/bevry/boundation)

## v3.0.0 2018 July 13

-   Removed `[fireMethod, instrospectionMethod]` for support of [unbounded](https://github.com/bevry/unbounded)
-   Updated [base files](https://github.com/bevry/base) and [editions](https://editions.bevry.me) using [boundation](https://github.com/bevry/boundation)

## v2.5.0 2016 May 14

-   No code changes in this release, just updated packaging
-   Now uses [Editions](https://editions.bevry.me) instead of [ESNextGuardian](https://github.com/bevry/esnextguardian)
-   Update dependencies

## v2.4.0 2015 December 9

-   Dropped Node 0.10 support, minimum node version supported is now 0.12
-   Updated dependencies

## v2.3.0 2015 September 5

-   Moved from CoffeeScript to ES6+
-   Removed `cyclic.js` as it should no longer be needed

## v2.2.0 2013 May 7

-   We no longer send the completion callback to functions executing synchronously
-   We now support optional arguments for functions executing asynchronously

## v2.1.6 2013 November 1

-   Dropped component.io and bower support, just use ender or browserify

## v2.1.5 2013 October 27

-   Re-packaged

## v2.1.4 2013 September 18

-   Fixed cyclic dependency problem on windows (since v2.1.3)
-   Added bower support

## v2.1.3 2013 September 18

-   Attempt at fixing circular dependency infinite loop (since v2.1.2)

## v2.1.2 2013 September 18

-   Added component.io support

## v2.1.1 2013 August 19

-   Republish with older verson of joe dev dependency to try and stop cyclic errors

## v2.1.0 2013 August 19

-   will now always return `null` for consistency
-   as return values are only possible with synchronous methods
-   will now ignore returned errors on asynchronous functions
-   asynchronous errors must now give the error via the completion callback
-   this is to avoid the possibility of the completion callback being called twice (once for the returned error via ambi, once via your application)
-   will now ignore thown errors
-   this was determined to be outside the scope of ambi, if you want this functionality use the more full featured [taskgroup package](http://npmjs.org/package/taskgroup)

## v2.0.0 2013 March 27

-   Split away from [bal-util](https://github.com/balupton/bal-util)
