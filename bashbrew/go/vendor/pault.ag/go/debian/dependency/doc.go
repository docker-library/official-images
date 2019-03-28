/*

The Dependency module provides an interface to parse and inspect Debian
Dependency relationships.


 Dependency                |               foo, bar (>= 1.0) [amd64] | baz
   -> Relations            | -> Relation        bar (>= 1.0) [amd64] | baz
        -> Possibilities   | -> Possibility     bar (>= 1.0) [amd64]
           | Name          | -> Name            bar
           | Version       | -> Version             (>= 1.0)
           | Architectures | -> Arch                          amd64
           | Stages        |
*/
package dependency // import "pault.ag/go/debian/dependency"
