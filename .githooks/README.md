# Git Hooks

Hooks in this directory check your commit message, and enforce versioning standards.

To use these hooks in your local workflow, run:

`git config core.hooksPath .githooks/hooks`

Read more about [customizing git hooks](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)

## Data versioning standards

If your commit does not have versioning instructions, you will get an error and the message:  
`"Aborting commit. Your commit message is missing versioning instructions. 
Please add [no version bump], [patch], [minor], or [major] to your commit message"`

### Guide to using the version tags:  
`[no version bump]` - Code changes that are not accompanied by data or file structure changes  
`[patch]` - Minor data corrections, or more significant code changes  
`[minor]` - Data additions or changes (the most commonly used tag)  
`[major]` - File structure or data shape changes, addition of new data types
