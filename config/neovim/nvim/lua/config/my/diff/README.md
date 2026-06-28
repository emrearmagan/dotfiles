# My CodeDiff

Custom extension for [codediff.nvim](https://github.com/esmuellert/codediff.nvim).

Uses [atlas.nvim](https://github.com/emrearmagan/atlas.nvim) UI components to show comments and threads.

Uses my `branch-notes` script for local branch notes:

```text
config/system/scripts/branch-notes
```

## Keymaps

| Key          | Mode          | Action                 |
| ------------ | ------------- | ---------------------- |
| `<leader>Rc` | normal/visual | Add pending PR comment |
| `<leader>RC` | normal/visual | Add PR comment         |
| `<leader>Rt` | normal        | Add PR task            |
| `<leader>Rv` | normal        | View PR thread         |
| `<leader>RV` | normal        | View pending review    |
| `<leader>Ra` | normal        | Approve PR             |
| `<leader>Rd` | normal        | Request PR changes     |
| `<leader>Rr` | normal        | Refresh PR comments    |
| `]c`         | normal        | Next PR comment        |
| `[c`         | normal        | Previous PR comment    |
| `]n`         | normal        | Next branch note       |
| `[n`         | normal        | Previous branch note   |
| `<leader>Rx` | normal        | Open PR                |
| `<leader>R?` | normal        | Show keymaps           |
