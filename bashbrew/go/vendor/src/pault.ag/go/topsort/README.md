topsort
=======

This package provides a handy interface to do a topological sort of
some data in a pretty lightweight way.

Example
-------

```go
package main

import (
	"fmt"

	"pault.ag/go/topsort"
)

func main() {
	network := topsort.NewNetwork()

	network.AddNode("watch tv while eating", nil)
	network.AddNode("make dinner", nil)
	network.AddNode("clean my kitchen", nil)

	/* Right, so the order of operations is next */

	network.AddEdge("clean my kitchen", "make dinner")
	// I need to clean the kitchen before I make dinner.

	network.AddEdge("make dinner", "watch tv while eating")
	// Need to make dinner before I can eat it.

	nodes, err := network.Sort()
	if err != nil {
		panic(err)
	}

	for _, step := range nodes {
		fmt.Printf(" -> %s\n", step.Name)
	}
	/* Output is:
	 *
	 * -> clean my kitchen
	 * -> make dinner
	 * -> watch tv while eating
	 */
}
```
