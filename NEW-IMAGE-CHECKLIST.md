# Checklist for Review

**NOTE:** This checklist is intended for the use of the Official Images maintainers both to track the status of your PR and to help inform you and others of where we're at. As such, please leave the "checking" of items to the repository maintainers. If there is a point below for which you would like to provide additional information or note completion, please do so by commenting on the PR. Thanks! (and thanks for staying patient with us :heart:)

-	[ ] associated with or contacted upstream?
-	[ ] does it fit into one of the common categories? ("service", "language stack", "base distribution")
-	[ ] is it reasonably popular, or does it solve a particular use case well?
-	[ ] does a [documentation](https://github.com/docker-library/docs/blob/master/README.md) PR exist? (should be reviewed and merged at roughly the same time so that we don't have an empty image page on the Hub for very long)
-	[ ] official-images maintainer dockerization review for best practices and cache gotchas/improvements (ala [the official review guidelines](https://github.com/docker-library/official-images/blob/master/README.md#review-guidelines))?
-	[ ] 2+ official-images maintainer dockerization review?
-	[ ] existing official images have been considered as a base? (ie, if `foobar` needs Node.js, has `FROM node:...` instead of grabbing `node` via other means been considered?)
-	[ ] if `FROM scratch`, tarballs only exist in a single commit within the associated history?
-	[ ] passes current tests? any simple new tests that might be appropriate to add? (https://github.com/docker-library/official-images/tree/master/test)
