# History

## v5.5.0 2019 November 11

-   Updated dependencies, [base files](https://github.com/bevry/base), and [editions](https://editions.bevry.me) using [boundation](https://github.com/bevry/boundation)

## v5.4.0 2018 November 20

-   Updated [base files](https://github.com/bevry/base) and [editions](https://github.com/bevry/editions) using [boundation](https://github.com/bevry/boundation)
-   Updated dependencies

## v5.3.0 2018 July 20

-   `clearRemaining` now returns the number of dropped items, `clear` continues to be chainable

## v5.2.0 2018 July 20

-   state of taskgroup is now updated before user events are emitted, to accurately represent current state
    -   this splits `itemDoneCallback` into `itemDoneCallbackUpdateState` and `itemDoneCallbackNextState`
-   nested events are now all bound at the same time
-   `task.add`, `group.add`, and `item.add` are now all emitted at the same time

## v5.1.0 2018 July 13

-   Add support for [unbounded](https://github.com/bevry/unbounded)
-   If a task completed, but had already completed earlier, we will now try to output the task's source for easier debugging

## v5.0.2 2018 July 13

-   Updated [base files](https://github.com/bevry/base) and [editions](https://github.com/bevry/editions) using [boundation](https://github.com/bevry/boundation)
-   Updated dependencies

## v5.0.1 2016 June 13

-   Added `clear` to `clearRemaining` alias for backwards compatibility between v4 and v5

## v5.0.0 2016 June 4

-   Changes to be impressed by:

    -   Dramatic performance improvements
        -   Improved performance of 10,000 tasks from 13 seconds to 1 seconds
        -   Improved memory footprint of 10,000 tasks from 130MB to 4MB (taken during completion event)
    -   Code has moved from CoffeeScript to ESNext
    -   Documentation is now powered by JSDoc
    -   Module is published with [Editions](https://github.com/bevry/editions)

-   Changes to be cautious about:

    -   Packaging:
        -   `require('taskgroup')` is no longer the TaskGroup class, you must again do `require('taskgroup').TaskGroup`
            -   It was too difficult to handle this across multiple environments without polluting scopes
    -   Task and TaskGroup:
        -   Once done, the item is now destroyed by default via the `destroyOnceDone` configuration option
            -   This means to add tasks to an already completed TaskGroup, you will need to set `destroyOnceDone` to `false`
            -   This will be a silent problem, unless coupled with a `pauseOnError`, `onError` or `onExit` deprecation error
        -   Running and completed tasks are no longer stored
            -   Completed items are now destroyed by default via TaskGroup's `destroyDoneItems` configuration option
            -   If you wish to store them, use the event listeners and disable `destroyDoneItems`
        -   `destroy()` now operates instantly, including removing all event listeners
            -   So if you did `.done().destroy().done()` the first done listener would be discarded
        -   Removed `exit()` method and `exit` configuration option
            -   They were complex, ambiguous, and undocumented
            -   `errorOnExcessCompletions` and `destroyOnceDone` configuration options are now provided
        -   Replaced `onError` and `pauseOnError` configuration options with `abortOnError` for better clarity
            -   Having two or more configuration options for this ability was overly complex
        -   Removed `sync` configuration option
            -   It was complex and only had one use case, which turned out was [better accomplished without it](https://github.com/bevry/safeps/releases/tag/v6.2.0)
        -   Renamed `includeInResults` configuration option to `storeResult` with improved functionality
            -   If `destroyOnceDone` is `true`, `storeResult` will default to `false`
        -   `done()`, `onceDone()`, and `whenDone()` now only listen for upcoming completions, rather than past
            -   Listening for past completions was too complex and could never guarantee consistent results
        -   `timeout` configuration option has been removed
            -   It is actually best and easily accomplished by your own task methods
        -   Removed configuration options will throw deprecation errors to ease migration
    -   TaskGroup:
        -   `results` state property renamed to `result`
        -   `addGroup()` method is now `addTaskGroup()`, alias provided
        -   Split `nestedConfig` configuration option into `nestedTaskConfig` and `nestedTaskGroupConfig`

-   Changes to be aware of:

    -   Task and TaskGroup:
        -   `started` event has been split into `pending` and `running` events for more accurate semantics
        -   Less used public APIs have now been marked as `private` or `public` depending on their use cases
        -   `getNames` method has been replaced by just `names` getter, which has its own `toString()` method that makes use of the `nameSeparator` configuration option, alias provided
        -   `getConfig()` method now `config` getter, alias provided
        -   `isCompleted() method now`completed` getter, alias provided
        -   `hasStarted()` method now `started` getter, alias provided
    -   TaskGroup:
        -   `getTotalItems()` method now `totalItems` getter, alias provided
        -   `getItemTotals()` method now `itemTotals getter, alias provided
    -   Task:
        -   If `domain` configuration option is `true` and domains are not available, an error will result
        -   More accurate error reporting for `completion` event
            -   It a state error occurred, but a argument error did not, it is possible this would not be reported to our done listener, this has been resolved
            -   done listener's error argument will now always be the stored error
            -   internal `result` storage now is stored without the error/first argument, as that is stored elsewhere

-   People to thank:

    -   [Peter Flannery](https://github.com/pflannery) for kickstarting the performance research and making it a priority

-   Issues closed:
    -   [An unusually large amount of memory usage - issue #19](https://github.com/bevry/taskgroup/issues/19)
    -   [Disabled optimisation issue: "bad value context for arguments value - issue #12](https://github.com/bevry/taskgroup/issues/12)

## v4.3.1 2015 December 10

-   Removed `cyclic.js` as the problem it solved was solved by npm v2 and above

## v4.3.0 2015 March 15

-   Now exports the TaskGroup class, of which `Task` and `TaskGroup` are now children
-   Added `Task` attribute on the TaskGroup class to allow over-riding of what should be the sub-task class
-   Added `TaskGroup` attribute on the TaskGroup class to allow over-riding of what should be the sub-taskgroup class
-   Added the `sync` configuration option, which when set to `true` will allow the execution of a Task or TaskGroup to execute synchronously
-   Updated dependencies

## v4.2.1 2015 February 20

-   Output more information about errors when a task completes twice

## v4.2.0 2015 February 2

-   Reintroduced `try...catch` for Node v0.8 and browser environments with a workaround to prevent error suppression
    -   Thanks to [kksharma1618](https://github.com/kksharma1618) for [issue #17](https://github.com/bevry/taskgroup/issues/17)
    -   Closes [issue #18](https://github.com/bevry/taskgroup/issues/17)
-   You can now ignore all the warnings from the v4.1.0 changelog as the behaviour is more or less the same as v4.0.5 but with added improvements

## v4.1.0 2015 February 2

-   This release fixes the errors in completion callbacks being swallowed/lost
    -   Thanks to [kksharma1618](https://github.com/kksharma1618) for [issue #17](https://github.com/bevry/taskgroup/issues/17)
-   The following changes have been made
    -   We no longer use `try...catch` at all, if you want error catching in your task, you must not disable domains (they are enabled by default) - [why?](https://github.com/bevry/taskgroup/issues/17#issuecomment-72383610)
    -   We now force exit the domain when the task's method calls its completion callback
    -   Domains now wrap only the firing of the task's method, rather than the preparation too as before
    -   Removed superflous check to ensure a task has a method before execution
    -   Ensured the actual check to ensure a task has a method before execution also checks if the method is actually a function (via checking for `.bind`) as the superflous check did
-   This **could** introduce the following issues in the following cases:
    -   You may get errors that were suppressed before now showing themselves, this is good, but it may cause unexpected things to break loudly that were breaking silently before
    -   If you have domains disabled and an error is thrown, you will get a different flow of logic than before as the error will be caught in your code, not TaskGroup's
    -   The domain's flow has improved, but this may cause a different flow than you were expecting previously
-   This **will** introduce the following issues in the following cases:
    -   If you are still on Node v0.8, synchronous errors and perhaps asynchronous errors thrown within your task method will no longer be caught by TaskGroup (due to Node 0.8's crippled domain functionality) and instead will need to be caught by your code either via preferably sent to the task method's completion callback rather than thrown, or via your own try...catch. But please upgrade to Node 0.10 or higher.
    -   If you are running TaskGroup in a web browser, you will need to catch errors manually or utilise a domain shim (browserify has one by default) - [why?](https://github.com/bevry/taskgroup/issues/18)
-   In other words, this release is the most stable yet, but do run your tests (you should always do this)

## v4.0.5 2014 August 3

-   Changed an error output to be of error type

## v4.0.4 2014 August 3

-   Added the ability to turn off using domains by setting the new task option `domain` to `false` (defaults to `true`)
-   Added the ability to turn off using [ambi](https://github.com/bevry/ambi) by setting the new task option `ambi` to `false` (defaults to `true`)

## v4.0.3 2014 July 11

-   Use `setImmediate` instead of `nextTick` to avoid `(node) warning: Recursive process.nextTick detected. This will break in the next version of node. Please use setImmediate for recursive deferral.` errors
-   Updated dependencies

## v4.0.2 2014 June 18

-   Added support for `done`, `whenDone`, `onceDone`, `once`, and `on` configuration options

## v4.0.1 2014 June 16

-   Fixed `Recursive process.nextTick detected` error (regression since v4.0.0)

## v4.0.0 2014 June 16

-   Significant rewrite with b/c breaks
    -   Completion listeners should now be accomplished via `.done(listener)` (listens once) or `.whenDone(listener)` (listener persists)
        -   These methods are promises in that they will execute the listener if the item is already complete
        -   They listen for the `done` event
    -   The execution of tasks and groups have had a great deal of investment to ensure execution is intuitive and consistent across different use cases
        -   Refer to to `src/lib/test/taskgroup-usage-test.coffee` for the guaranteed expectations across different scenarios
    -   In earlier versions you could use `tasks.exit()` during execution to clear remaning items, stop execution, and exit, you can no longer do this, instead use the completion callback with an error, or call `tasks.clear()` then the completion callback
    -   Refer to the [new public api docs](http://learn.bevry.me/taskgroup/api) for the latest usage
-   Changes
    -   `complete` event is now `completed`, but you really should be using the new `done` event or the promise methods
    -   `run` event is now `started`
    -   A lot of internal variables and methods have had their functionality changed or removed, if a method or variable is not in the [public api](http://learn.bevry.me/taskgroup/api), do not use it
    -   There is now a default `error` and `completed` listener that will emit the `done` event if there are listeners for it, if there is no `done` event listeners, and an error has occured, we will throw the error
    -   Tasks and groups will now only receive a default name when required, this is to prevent set names from being over-written by the default
    -   Adding of tasks and groups to a group instance will now return the group instance rather than the added tasks to ensure chainability, if you want the created tasks, use `.createTask(...)` and `.createGroup(...)` instead, then add the result manually
-   Introductions
    -   `passed`, `failed`, `destroyed` events are new
    -   Task only
        -   new `timeout` option that accepts a number of milliseconds to wait before throwing an error
        -   new `onError` option that defaults to `'exit'` but can also accept `'ignore'` which will ignore duplicated exit errors (useful when combined with timeout event)
    -   TaskGroup only
        -   new `onError` option that defaults to `'exit'` but can also accept `'ignore'` which will ignore all task errors
        -   new `setNestedConfig(config)` and `setNestedTaskConfig(config)` options to set configuration for all children

## v3.4.0 2014 May 8

-   Added `context` option for Task, to perform a late bind on the method
-   Asynchronous task methods can now accept optional arguments thanks to new [ambi](https://github.com/bevry/ambi) version
-   Updated dependencies

## v3.3.9 2014 May 4

-   Added [extendonclass](https://github.com/bevry/extendonclass) support
-   Added `Task.create` and `TaskGroup.create` helpers
-   Will no longer fail if an invalid argument is passed as configuration
-   Updated dependencies

## v3.3.8 2014 February 5

-   More descriptive error when a task is fired without a method to fire

## v3.3.7 2014 January 30

-   Improvements around adding tasks to task groups and passing arguments to Task and TaskGroup constructors

## v3.3.6 2013 November 29

-   Properly fixed v3.3.3 issue while maintaining node.js v0.8 and browserify support
    -   Thanks to [pflannery](https://github.com/pflannery) for [pull request #11](https://github.com/bevry/taskgroup/pull/11)

## v3.3.5 2013 November 28

-   Re-added Node.js v0.8 support (regression since v3.3.3)

## v3.3.4 2013 November 27

-   Fixed the v3.3.3 fix

## v3.3.3 2013 November 27

-   Fixed possible "(node) warning: Recursive process.nextTick detected. This will break in the next version of node. Please use setImmediate for recursive deferral." error under certain circumstances

## v3.3.2 2013 November 19

-   Don't add or create empty tasks and groups

## v3.3.1 2013 November 6

-   Fixed child event bubbling by using duck typing (regression since v3.3.0)
-   Better error handling on uncaught task exceptions
-   Tasks will now get a default name set to ease debugging

## v3.3.0 2013 November 1

-   Bindings are now more explicit
-   Improved configuration parsing
-   Configuration is now accessed via `getConfig()`
-   Dropped component.io and bower support, just use ender or browserify

## v3.2.4 2013 October 27

-   Re-packaged

## v3.2.3 2013 September 18

-   Fixed cyclic dependency problem on windows (since v2.1.3)
-   Added bower support

## v3.2.2 2013 September 18

-   Component.io compatibility

## v3.2.1 2013 August 19

-   Republish with older version of joe dev dependency to try and stop cyclic errors
-   Better node 0.8 support when catching thrown errors

## v3.2.0 2013 August 19

-   Wrapped Task execution in a domain to catch uncaught errors within the task execution, as well as added checks to ensure the completion callback does not fire multiple times
    -   These will be reported via the `error` event that the Task will emit
        -   If the Task is part of a TaskGroup, the TaskGroup will listen for this, kill the TaskGroup and emit an `error` event on the TaskGroup
-   Moved from EventEmitter2 to node's own EventEmitter to ensure domain compatibility

## v3.1.2 2013 April 6

-   Added `getTotals()` to `TaskGroup`
-   Added `complete()` to `Task`

## v3.1.1 2013 April 5

-   Fixed task run issue under certain circumstances
-   Added `exit(err)` function

## v3.1.0 2013 April 5

-   Tasks can now have the arguments that are sent to them customized by the `args` configuration option
-   Group inline functions now support an optional completion callback
-   Group events for items now have their first argument as the item the event was for

## v3.0.0 2013 April 5

-   Significant rewrite and b/c break

## v2.0.0 2013 March 27

-   Split from [bal-util](https://github.com/balupton/bal-util) / [bal-util history](https://github.com/balupton/bal-util/blob/master/HISTORY.md#files)
