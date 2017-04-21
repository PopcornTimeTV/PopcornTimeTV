# Contributing


## Code Style

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

## Issues

When creating an issue please make sure to follow the issue template provided. Failure to do so will result in your issue being immediately closed and marked with the **"incorrect use of issue template"** tag. Repeated ignorance of the issue template may result in your account being blocked from posting any more issues/pull requests.

1. The three ellipses (...) that follow every point are to be **REMOVED** when you add your contents. They are purely there to show you where to write. When have you ever seen an english sentence starting with "...hi how are you today".

2. You can add or remove steps depending on how many steps it takes to reproduce your issue. **DO NOT** put nonsense in steps 2 and 3 if you only use step 1.

3. Ticking is either done manually in the "Preview" section of the comment box or by putting an x in between the two square braces like so [x].

4. Parts of the issue template are not to be omitted if you think they're not necessary/don't apply to you. The only time you can edit the issue template is if your issue is an enhancement. In that case, the whole issue template is to be removed.


## Pull Requests

If your pull request contains UI changes, please include screenshots for demo purposes.

Before submitting a pull request test your changes and make sure they work as intended.
