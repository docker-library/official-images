# Checklist for Review

-	[ ] associated with or contacted upstream?
-	[ ] does it fit into one of the common categories? ("service", "language stack", "base distribution")
-	[ ] is it reasonably popular, or does it solve a particular use case well?
-	[ ] does a [documentation](https://github.com/docker-library/docs/blob/master/README.md) PR exist? (should be reviewed and merged at roughly the same time so that we don't have an empty image page on the Hub for very long)
-	[ ] dockerization review for best practices and cache gotchas/improvements (ala [the official review guidelines](https://github.com/docker-library/official-images/blob/master/README.md#review-guidelines))?
-	[ ] 2+ dockerization review?
-	[ ] existing official images have been considered as a base? (ie, if `foobar` needs Node.js, has `FROM node:...` instead of grabbing `node` via other means been considered?)
-	[ ] if `FROM scratch`, tarballs only exist in a single commit within the associated history?
-	[ ] passes current tests? any simple new tests that might be appropriate to add? (https://github.com/docker-library/official-images/tree/master/test)
