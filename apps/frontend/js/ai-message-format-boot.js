(function (root) {
    "use strict";

    var m = root.PngAiMessageFormat;
    if (!m) {
        throw new Error(
            "Missing PngAiMessageFormat: load /static/js/ai-message-format.js before ai-message-format-boot.js."
        );
    }
    if (
        typeof m.formatAiMessageHtml !== "function" ||
        typeof m.formatTextForSpeech !== "function" ||
        typeof m.escapeHtml !== "function"
    ) {
        throw new Error("Incomplete PngAiMessageFormat API from ai-message-format.js.");
    }

    root.PngAiMessageFormat = m;
})(
    typeof window !== "undefined"
        ? window
        : typeof globalThis !== "undefined"
          ? globalThis
          : this
);
