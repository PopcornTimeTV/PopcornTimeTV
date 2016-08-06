#Contributing


##Code Style

When contributing make use to ommit the `self` prefex when calling variables, unless they are being called within a closure. 

When defining a function, the opening brace must be on the same line as the function declaration. i.e.

```
func myFunction(var: String) {
	/* ... */
}
```


##Pull Requests

If your pull request contains UI changes, please include screenshots for demo purposes. 

Before submitting a pull request test your changes and make sure they work as intended. We require that the project be linted. This can be accomplished by installing Swiftlint. If you have Homebrew installed simply run `brew install swiftlint`

Once you have it installed, cd into the directory and run `swiftlint`. This will go through and alert you of any issues there might be with the formatting such as a colon being out place when defining a variable, or if an optional is being foreunwrapped when it sohuld be checked.