(function (root) {
    "use strict";

    function escapeHtml(str) {
        if (str == null) return "";
        var div = document.createElement("div");
        div.textContent = String(str);
        return div.innerHTML;
    }

    function splitAiTableCells(line) {
        var t = line.trim();
        if (!t.includes("|")) return [];
        if (t.startsWith("|")) t = t.slice(1).trimStart();
        if (t.endsWith("|")) t = t.slice(0, -1).trimEnd();
        return t.split("|").map(function (c) {
            return c.trim();
        });
    }

    function isAiTableSeparatorRow(line) {
        var cells = splitAiTableCells(line);
        if (cells.length < 2) return false;
        return cells.every(function (cell) {
            return /^:?-{2,}:?$/.test(cell.replace(/\s/g, ""));
        });
    }

    function isAiTableRowLine(line) {
        return splitAiTableCells(line).length >= 2;
    }

    function formatAiCellHtml(rawCell) {
        var h = escapeHtml(rawCell != null ? rawCell : "");
        h = h.replace(
            /\*\*([^*]+)\*\*/g,
            '<strong class="ai-msg-strong">$1</strong>'
        );
        h = h.replace(/`([^`]+)`/g, '<code class="ai-inline-code">$1</code>');
        return h;
    }

    function buildAiGfmTableHtml(block) {
        var headerCells = splitAiTableCells(block[0]);
        var colCount = headerCells.length;
        var h =
            '<div class="ai-msg-table-wrap"><table class="ai-msg-table"><thead><tr>';
        headerCells.forEach(function (c) {
            h += "<th>" + formatAiCellHtml(c) + "</th>";
        });
        h += "</tr></thead><tbody>";
        for (var r = 2; r < block.length; r++) {
            var cells = splitAiTableCells(block[r]);
            h += "<tr>";
            for (var c = 0; c < colCount; c++) {
                h += "<td>" + formatAiCellHtml(cells[c] != null ? cells[c] : "") + "</td>";
            }
            h += "</tr>";
        }
        h += "</tbody></table></div>";
        return h;
    }

    function buildAiPlainTableHtml(block) {
        var colCount = Math.max.apply(
            null,
            [0].concat(
                block.map(function (ln) {
                    return splitAiTableCells(ln).length;
                })
            )
        );
        var h =
            '<div class="ai-msg-table-wrap"><table class="ai-msg-table"><tbody>';
        block.forEach(function (row) {
            var cells = splitAiTableCells(row);
            h += "<tr>";
            for (var c = 0; c < colCount; c++) {
                h += "<td>" + formatAiCellHtml(cells[c] != null ? cells[c] : "") + "</td>";
            }
            h += "</tr>";
        });
        h += "</tbody></table></div>";
        return h;
    }

    function extractAiMarkdownTables(text) {
        var tables = [];
        var lines = text.split("\n");
        var out = [];
        var i = 0;
        while (i < lines.length) {
            if (!isAiTableRowLine(lines[i])) {
                out.push(lines[i]);
                i++;
                continue;
            }
            var j = i;
            var block = [];
            while (j < lines.length && isAiTableRowLine(lines[j])) {
                block.push(lines[j]);
                j++;
            }
            var consumed = false;
            if (block.length >= 2 && isAiTableSeparatorRow(block[1])) {
                tables.push(buildAiGfmTableHtml(block));
                out.push("__PNG_AI_TBL_" + (tables.length - 1) + "__");
                i = j;
                consumed = true;
            } else if (block.length >= 2) {
                var counts = block.map(function (ln) {
                    return splitAiTableCells(ln).length;
                });
                var n = counts[0];
                if (n >= 2 && counts.every(function (c) {
                    return c === n;
                })) {
                    tables.push(buildAiPlainTableHtml(block));
                    out.push("__PNG_AI_TBL_" + (tables.length - 1) + "__");
                    i = j;
                    consumed = true;
                }
            }
            if (!consumed) {
                out.push(lines[i]);
                i++;
            }
        }
        return { text: out.join("\n"), tables: tables };
    }

    function formatAiMessageHtml(raw) {
        if (raw == null || raw === "") return "";
        var codeBlocks = [];
        var afterCode = String(raw).replace(
            /```(?:[\w-]*\n)?([\s\S]*?)```/g,
            function (_, code) {
                var id = codeBlocks.length;
                codeBlocks.push(
                    '<pre class="ai-code-block"><code>' +
                        escapeHtml(code.trim()) +
                        "</code></pre>"
                );
                return "\n\n__PNG_AI_BLK_" + id + "__\n\n";
            }
        );
        var extracted = extractAiMarkdownTables(afterCode);
        var tableBlocks = extracted.tables;
        var withPlaceholders = extracted.text;
        var html = escapeHtml(withPlaceholders);
        html = html.replace(
            /\*\*([^*]+)\*\*/g,
            '<strong class="ai-msg-strong">$1</strong>'
        );
        html = html.replace(/`([^`]+)`/g, '<code class="ai-inline-code">$1</code>');
        for (var bi = 0; bi < codeBlocks.length; bi++) {
            html = html.replace("__PNG_AI_BLK_" + bi + "__", codeBlocks[bi]);
        }
        for (var t = 0; t < tableBlocks.length; t++) {
            html = html.replace("__PNG_AI_TBL_" + t + "__", tableBlocks[t]);
        }
        var chunks = html.split(/\n\n+/);
        var body = chunks
            .map(function (chunk) {
                chunk = chunk.trim();
                if (!chunk) return "";
                if (chunk.indexOf('<pre class="ai-code-block">') !== -1) return chunk;
                if (chunk.indexOf("ai-msg-table-wrap") !== -1) return chunk;
                var lines = chunk.split("\n");
                var nonEmpty = lines.filter(function (l) {
                    return l.trim();
                });
                var allBullets =
                    nonEmpty.length > 1 &&
                    nonEmpty.every(function (l) {
                        return /^(?:[-*•]|\d+\.)\s/.test(l.trim());
                    });
                if (allBullets) {
                    return (
                        '<ul class="ai-msg-list">' +
                        nonEmpty
                            .map(function (l) {
                                var tt = l
                                    .trim()
                                    .replace(/^(?:[-*•]|\d+\.)\s+/, "");
                                return "<li>" + tt + "</li>";
                            })
                            .join("") +
                        "</ul>"
                    );
                }
                return (
                    '<div class="ai-msg-para">' + lines.join("<br>") + "</div>"
                );
            })
            .filter(Boolean)
            .join("");
        return body ? '<div class="ai-msg-body">' + body + "</div>" : "";
    }

    function stripAiMarkdownForSpeech(cell) {
        if (cell == null) return "";
        var t = String(cell);
        t = t.replace(/\*\*([^*]+)\*\*/g, "$1");
        t = t.replace(/`([^`]+)`/g, "$1");
        return t.trim();
    }

    function tableBlockToSpeechSummary(block, hasHeader) {
        if (hasHeader) {
            var headers = splitAiTableCells(block[0]).map(stripAiMarkdownForSpeech);
            var rowParts = [];
            for (var r = 2; r < block.length; r++) {
                var cells = splitAiTableCells(block[r]);
                var pairs = [];
                for (var c = 0; c < headers.length; c++) {
                    var label = headers[c] || "Column " + (c + 1);
                    var val = stripAiMarkdownForSpeech(
                        cells[c] != null ? cells[c] : ""
                    );
                    pairs.push(label + ": " + val);
                }
                rowParts.push(pairs.join(", "));
            }
            return "Table. " + rowParts.join(". ") + ".";
        }
        var rowParts = [];
        for (var rr = 0; rr < block.length; rr++) {
            var rowCells = splitAiTableCells(block[rr]).map(
                stripAiMarkdownForSpeech
            );
            rowParts.push(rowCells.join(", "));
        }
        return "Table. " + rowParts.join(". ") + ".";
    }

    function formatTextForSpeech(raw) {
        if (raw == null || raw === "") return "";
        var s = String(raw);
        s = s.replace(
            /```(?:[\w-]*\n)?([\s\S]*?)```/g,
            " Code block omitted. "
        );
        var lines = s.split("\n");
        var out = [];
        var i = 0;
        while (i < lines.length) {
            if (!isAiTableRowLine(lines[i])) {
                out.push(lines[i]);
                i++;
                continue;
            }
            var j = i;
            var block = [];
            while (j < lines.length && isAiTableRowLine(lines[j])) {
                block.push(lines[j]);
                j++;
            }
            var consumed = false;
            if (block.length >= 2 && isAiTableSeparatorRow(block[1])) {
                out.push(tableBlockToSpeechSummary(block, true));
                i = j;
                consumed = true;
            } else if (block.length >= 2) {
                var counts = block.map(function (ln) {
                    return splitAiTableCells(ln).length;
                });
                var n = counts[0];
                if (
                    n >= 2 &&
                    counts.every(function (c) {
                        return c === n;
                    })
                ) {
                    out.push(tableBlockToSpeechSummary(block, false));
                    i = j;
                    consumed = true;
                }
            }
            if (!consumed) {
                out.push(lines[i]);
                i++;
            }
        }
        s = out.join("\n");
        s = s.replace(/\*\*([^*]+)\*\*/g, "$1");
        s = s.replace(/`([^`]+)`/g, "$1");
        s = s.replace(/#{1,6}\s+/gm, "");
        s = s.replace(/^\s*[-*•]\s+/gm, "");
        s = s.replace(/^\s*\d+\.\s+/gm, "");
        s = s.replace(/\s+/g, " ").trim();
        return s;
    }

    var api = {
        escapeHtml: escapeHtml,
        formatAiMessageHtml: formatAiMessageHtml,
        formatTextForSpeech: formatTextForSpeech,
    };

    var requiredApi = ["escapeHtml", "formatAiMessageHtml", "formatTextForSpeech"];
    for (var ri = 0; ri < requiredApi.length; ri++) {
        var key = requiredApi[ri];
        if (typeof api[key] !== "function") {
            throw new Error("PngAiMessageFormat: missing implementation for " + key);
        }
    }
    Object.freeze(api);

    root.PngAiMessageFormat = api;
})(
    typeof window !== "undefined"
        ? window
        : typeof globalThis !== "undefined"
          ? globalThis
          : this
);
