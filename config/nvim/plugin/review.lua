--[[
-- Local code review notes.
--
-- Annotate lines while reading a diff; notes are appended to REVIEW.md in the
-- repo root as `path:line — text`, which agents resolve back to the source.
--]]

local function git_root()
    local out = vim.fn.systemlist({ "git", "rev-parse", "--show-toplevel" })
    if vim.v.shell_error ~= 0 or not out[1] or out[1] == "" then
        return nil
    end
    return out[1]
end

-- A real file buffer always wins: after jumping out of the diff with a
-- go-to-definition, the buffer is the truth while diffview's current file is
-- still whatever the panel has selected. Only virtual buffers (the git blob
-- side of a diff, the file panel) are worth asking diffview about.
local function cursor_target()
    local bufname = vim.api.nvim_buf_get_name(0)

    if vim.bo.buftype == "" and vim.fn.filereadable(bufname) == 1 then
        return { path = bufname, line = vim.fn.line("."), old_side = false }
    end

    local ok, lib = pcall(require, "diffview.lib")
    local view = ok and lib.get_current_view() or nil
    if not view then return nil end

    local in_panel = view.panel:is_focused()
    -- In the panel the cursor may sit on a header or a folded dir; fall back
    -- to whatever file the diff windows are currently showing.
    local file = view:infer_cur_file() or (view.panel and view.panel.cur_file)
    if not file or not file.absolute_path then return nil end

    return {
        path = file.absolute_path,
        line = not in_panel and vim.fn.line(".") or nil,
        old_side = not in_panel,
    }
end

local function relative_to(root, path)
    if path:sub(1, #root + 1) == root .. "/" then
        return path:sub(#root + 2)
    end
    return path
end

local function add_note()
    local root = git_root()
    if not root then
        vim.notify("Not inside a git repository", vim.log.levels.WARN)
        return
    end

    local target = cursor_target()
    if not target then
        vim.notify("No file under the cursor", vim.log.levels.WARN)
        return
    end

    local ref = relative_to(root, target.path)
    if target.line then
        ref = ref .. ":" .. target.line
    end
    if target.old_side then
        ref = ref .. " (old side)"
    end

    vim.ui.input({ prompt = "Review note for " .. ref .. ": " }, function(text)
        if not text or text:match("^%s*$") then return end

        local notes = root .. "/REVIEW.md"
        local f, err = io.open(notes, "a")
        if not f then
            vim.notify("Cannot write " .. notes .. ": " .. tostring(err), vim.log.levels.ERROR)
            return
        end
        f:write(string.format("- %s — %s\n", ref, text))
        f:close()

        vim.notify("Noted: " .. ref)
    end)
end

local function open_notes()
    local root = git_root()
    if not root then
        vim.notify("Not inside a git repository", vim.log.levels.WARN)
        return
    end
    vim.cmd.split(vim.fn.fnameescape(root .. "/REVIEW.md"))
end

vim.keymap.set("n", "<leader>gc", add_note, { desc = "Review: note the line under the cursor" })
vim.keymap.set("n", "<leader>gC", open_notes, { desc = "Review: open REVIEW.md" })
