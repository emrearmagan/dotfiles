--------------------------------------------------------------------------------
-- Session
--------------------------------------------------------------------------------

---@class DiffCommentsSession
---@field git_root string
---@field original_path string|nil
---@field modified_path string|nil
---@field original_bufnr integer
---@field modified_bufnr integer
---@field original_revision string|nil
---@field modified_revision string|nil

--------------------------------------------------------------------------------
-- Pull Request
--------------------------------------------------------------------------------

---@class DiffCommentsPR
---@field number string|integer
---@field owner string|nil
---@field repo string|nil
---@field workspace string|nil
---@field url string
---@field node_id string|nil
---@field _raw any|nil

--------------------------------------------------------------------------------
-- Comment
--------------------------------------------------------------------------------

---@class DiffComment
---@field id string|integer
---@field node_id string|nil
---@field parent_id string|integer|nil
---@field parent DiffComment|nil
---@field thread_id string|integer|nil
---@field author {name: string|nil, username: string|nil}|nil
---@field body string
---@field context DiffCommentContext|nil
---@field state "PENDING"|"RESOLVED"|"OUTDATED"|"DELETED"|nil
---@field is_task boolean|nil
---@field created_at string|nil
---@field updated_at string|nil
---@field url string|nil
---@field _raw any|nil

--------------------------------------------------------------------------------
-- Write context
--------------------------------------------------------------------------------

---@class DiffCommentContext
---@field file_path string
---@field start_line integer
---@field end_line integer
---@field side "LEFT"|"RIGHT"

--------------------------------------------------------------------------------
-- Provider Interface
--------------------------------------------------------------------------------

---@class DiffCommentsProvider
---@field name string
---@field icon string|nil
---@field hl_group string|nil
---@field allow_out_of_diff_comments boolean|nil
---
---@field can_handle fun(session: DiffCommentsSession): boolean
---
---@field find_pr fun(session: DiffCommentsSession, on_done: fun(pr: DiffCommentsPR|nil, err: string|nil))
---@field fetch_comments fun(pr: DiffCommentsPR, on_done: fun(comments: DiffComment[], err: string|nil))
---
---@field add_comment fun(pr: DiffCommentsPR, comment: DiffComment, on_done: fun(created: DiffComment|nil, err: string|nil))
---@field edit_comment fun(pr: DiffCommentsPR, comment: DiffComment, on_done: fun(updated: DiffComment|nil, err: string|nil))
---@field delete_comment fun(pr: DiffCommentsPR, comment: DiffComment, on_done: fun(ok: boolean|nil, err: string|nil))
---@field resolve_thread (fun(pr: DiffCommentsPR, root: DiffComment, on_done: fun(ok: boolean|nil, err: string|nil)))|nil
---@field unresolve_thread (fun(pr: DiffCommentsPR, root: DiffComment, on_done: fun(ok: boolean|nil, err: string|nil)))|nil
---@field submit_review (fun(pr: DiffCommentsPR, event: "APPROVE"|"REQUEST_CHANGES"|"COMMENT", body: string, on_done: fun(ok: boolean|nil, err: string|nil)))|nil
---
--- Misc:
---@field pr_url fun(pr: DiffCommentsPR): string|nil

return {}
