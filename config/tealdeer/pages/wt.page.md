# wt

> Worktrunk: manage git worktrees.
> `wt open` and `wt review` come from these dotfiles.
> More information: <https://worktrunk.dev>.

- Switch to a branch's worktree, creating it if needed:

`wt switch {{branch}}`

- Create a new branch and its worktree, then start pi there:

`wt switch --create {{branch}} -x pi`

- List worktrees and their status:

`wt list`

- Remove the current worktree (deletes the branch only if merged):

`wt remove`

- Remove a worktree but keep its branch:

`wt remove --no-delete-branch {{branch}}`

- Throw away a worktree and its branch, even if unmerged or with uncommitted changes:

`wt remove -D -f {{branch}}`

- Squash the current branch into the default branch locally, then remove its worktree:

`wt merge`

- Open a tmux window in a branch's worktree (created if needed), in the current session:

`wt open {{branch}}`

- Review a branch with pi and an Atlas diff side by side (tmux session `reviews`):

`wt review {{branch}} --attach`

- Review a pull request against another base branch:

`wt review {{branch}} --base={{develop}} --target={{https://github.com/owner/repo/pull/123}}`
