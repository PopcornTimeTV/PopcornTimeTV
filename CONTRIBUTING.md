#Contributing


##Code Style

When contributing make sure to omit the `self` prefix when calling variables, unless they are being called within a closure.

Also omit the `init` keyword, try to not use semaphores and make sure to correctly use optional variables as string concatenation has been changed in `Swift 3.0`

When defining a function, the opening brace must be on the same line as the function declaration. i.e.

```
func myFunction(var: String) {
	/* ... */
}
```

Make sure to comment what you are doing if it is especially tricky using Xcode's build in [markup language](https://developer.apple.com/library/content/documentation/Xcode/Reference/xcode_markup_formatting_ref/)

eg. for functions/class/struct/enum:

```
/**
	Brief description of what function/class/struct/enum does.

	**capitalize the first letter**
	- **P**arameter name: Explanation.

	- Important: Any important stuff

	- Returns: What the function returns if any.
*/

```


##Pull Requests

If your pull request contains UI changes, please include screenshots for demo purposes.

Before submitting a pull request test your changes and make sure they work as intended.
