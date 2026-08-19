# Commit & push changes

This GitHub Action commits and pushes changes which have been made by precedent
steps, if there are any changes.

This is mostly useful in the case were an automated process (like Renovate)
updates some value somewhere in the repository and another process requires to
propagate the Renovate update to multiple files (aka. "golden files").

> [!WARNING]
>
> This action will fail if there are "too many" commits (more than 3 by
> default) done by the same author using the "commit message" that would be
> used to commit the changes later on, in the opened branch.
>
> This is a protection mechanism to prevent GitHub Action to create too many
> new runs because a change was made from GitHub Action itself.
>
> To enable this protection mechanism, use the `fetch-depth: 0` option of
> `actions/checkout`.


# Pre-requisites

Your job needs to have the permission to push in the repository:

```yaml
jobs:
  something:
    runs-on: ubuntu-latest
    name: Something

    permissions:
      contents: write
```

In addition, if you want to detect infinite loop of GitHub Action runs triggered by git push from this action, fetch all the branches at the beginning of the workflow with the `fetch-depth: 0` option from the `actions/checkout` GitHub Action:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0 # fetch all the branches, not only the current one
```

This will fetch the current branch plus all the other branches, and allow to
detect how many commits were done by the author between the main branch and the
current one, in order to detect endless commits.

## How to use?

```yaml
steps:
  - uses: camunda/action-git-commit@v1
```

You can specify an alternative Git commit message:

```yaml
steps:
  - uses: camunda/action-git-commit@v1
    with:
      commit-message: Hey ho, here are some changes!
```

You can specify a commit author:

```yaml
steps:
  - uses: camunda/action-git-commit@v1
    with:
      commit-message: Hey ho, here are some changes!
      author-name: Bob
      author-email: bob@example.com
```

The action output a `changes-pushed` value if changes have been pushed:

```yaml
steps:
  - uses: camunda/action-git-commit@v1
    id: commit

  - if: ${{ steps.commit.outputs.changes-pushed == 'true' }}
    run: Changes have been pushed!
```
