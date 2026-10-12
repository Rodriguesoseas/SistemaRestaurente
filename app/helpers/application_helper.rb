module ApplicationHelper
  ICON_PATHS = {
    "flame" => "M12 3c2 5-2 6 1 9 1-2 3-3 3-5 4 4 5 8 2 11a8 8 0 0 1-12-1c-2-4 1-8 6-14Z",
    "menu" => "M4 6h16M4 12h16M4 18h16",
    "dashboard" => "M3 3h7v7H3zM14 3h7v7h-7zM3 14h7v7H3zM14 14h7v7h-7z",
    "tables" => "M4 4h16v7H4zM6 11v9M18 11v9M3 16h18",
    "cash" => "M3 7h18v13H3zM7 7V3h10v4M7 12h2M15 12h2M7 16h10",
    "movements" => "M3 7h17l-4-4M21 17H4l4 4M20 7l-4 4M4 17l4-4",
    "stock" => "m12 3 9 5-9 5-9-5 9-5Zm-9 5v10l9 4 9-4V8M12 13v9M7 5l10 6",
    "reports" => "M4 3v18h17M8 16v-4M13 16V8M18 16V5",
    "logout" => "M9 4H4v16h5M10 12h11M17 8l4 4-4 4",
    "income" => "M12 3v14M6 11l6 6 6-6M4 21h16",
    "expense" => "M12 17V3M6 9l6-6 6 6M4 21h16",
    "result" => "M4 19h16M6 14l4-4 4 3 6-9M15 4h5v5"
  }.freeze

  def icon(name)
    tag.svg(viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": 1.7,
            "stroke-linecap": "round", "stroke-linejoin": "round", class: "size-5 shrink-0", "aria-hidden": true) do
      tag.path(d: ICON_PATHS.fetch(name))
    end
  end
end
