-- image_path.lua
-- Prefix bare image filenames with attachments/<note-basename>/ or attachments/

-- Path separator (handles Windows/macOS/Linux)
local sep = package.config:sub(1,1)

-- Try to detect the input note's basename (without extension)
local doc_basename = ""
if PANDOC_STATE and PANDOC_STATE.input_files and #PANDOC_STATE.input_files > 0 then
  local first = PANDOC_STATE.input_files[1]
  -- strip directories
  local fname = first:gsub("^.*[/\\]", "")
  -- strip extension
  doc_basename = fname:gsub("%.[^%.]+$", "")
end

-- Utility: does the path already include a directory?
local function has_dir(p)
  return p:match("[/\\]") ~= nil
end

-- If no dir, prefix with attachments/<doc_basename>/ (or attachments/)
local function ensure_image_path(p)
  if has_dir(p) then return p end
  if doc_basename ~= "" then
    return "attachments" .. sep .. doc_basename .. sep .. p
  else
    return "attachments" .. sep .. p
  end
end

-- Rewrite Image elements
function Image(el)
  if el.src and el.src ~= "" then
    el.src = ensure_image_path(el.src)
  end
  return el
end

-- Rewrite images inside Figures (Pandoc >= 3 can produce Figure blocks)
function Figure(el)
  for i, blk in ipairs(el.content or {}) do
    if blk.t == "Plain" or blk.t == "Para" then
      for j, inl in ipairs(blk.content or {}) do
        if inl.t == "Image" and inl.src then
          inl.src = ensure_image_path(inl.src)
        end
      end
    end
  end
  return el
end
