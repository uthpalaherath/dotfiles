--[[
  Reusable LaTeX preambles
  Source the preamble file specified in the defaults file or the frontmatter

  By github.com/zcysxy
--]]

local raw_user_dir = ""
if type(PANDOC_STATE) == "table" and PANDOC_STATE["user_data_dir"] then
    raw_user_dir = PANDOC_STATE["user_data_dir"]
end

-- escape spaces / tildes like original and add trailing slash only when non-empty
local user_dir = ""
if raw_user_dir and raw_user_dir ~= "" then
    user_dir = raw_user_dir:gsub(" ", "\\space "):gsub("~", "\\string~") .. "/"
end

local basic_preamble = [[
\usepackage{xcolor}
\usepackage{tcolorbox}
\tcbuselibrary{skins,breakable}
\usepackage{algorithm}
\usepackage[noEnd=false,indLines=false]{algpseudocodex}
\usepackage{tikz}
\usepackage{amsthm}
\newtheorem{theorem}{Theorem}[section]
\newtheorem{fact}{Fact}[section]
\newtheorem{proposition}{Proposition}[section]
\theoremstyle{definition}
\newtheorem{definition}{Definition}[section]
\newtheorem{assumption}{Assumption}[section]
\usepackage[normalem]{ulem} % use normalem to protect \emph
\usepackage{soul}
\renewcommand\hl{\bgroup\markoverwith
  {\textcolor{yellow}{\rule[-.5ex]{2pt}{2.5ex}}}\ULon}
]]

-- Helper: return a plain string from metadata value (works for MetaString / raw types)
local function meta_to_string(mval)
    if mval == nil then return nil end
    -- pandoc's metadata might be a MetaInlines/MetaString; tostring is fine in most filters
    return tostring(mval)
end

function Meta(m)
    local header = m['header-includes'] and m['header-includes'] or pandoc.List()
    table.insert(header, 1, pandoc.RawBlock("tex", basic_preamble))

    -- If the user supplied preamble-file in metadata, add it.
    local pf = meta_to_string(m['preamble-file'])
    if pf and pf ~= "" then
        -- strip trailing .sty if present
        local pf_clean = pf:gsub("%.sty$", "")

        -- determine whether pf_clean is absolute (starts with /) or relative
        local use_path
        if pf_clean:match("^/") then
            use_path = pf_clean
        else
            -- if user_dir empty, fallback to pf_clean as-is (relative to cwd)
            use_path = (user_dir ~= "" and user_dir .. pf_clean) or pf_clean
        end

        -- create \usepackage{"<path>"} line (escape backslashes handled by Lua string)
        local preamble_line = pandoc.RawInline("tex", "\\usepackage{\"" .. use_path .. "\"}")
        table.insert(header, 1, preamble_line)
    end

    m["header-includes"] = header
    return m
end
