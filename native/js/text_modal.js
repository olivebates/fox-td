function showTextModal({input = "", atitle = "Import Save", subtitle = "Please paste your save string into the field below.", button = "Import Save"} = {}) {
    const modal = document.createElement("div");
    modal.style.cssText = "position:fixed;top:0;left:0;width:100%;height:100%;background:rgba(0,0,0,0.6);display:flex;align-items:center;justify-content:center;z-index:1000;font-family:Arial,sans-serif;";

    const content = document.createElement("div");
    content.style.cssText = "background:white;padding:24px;border-radius:12px;max-width:480px;width:90%;box-shadow:0 8px 20px rgba(0,0,0,0.3);text-align:center;";

    const titleEl = document.createElement("h2");
    titleEl.textContent = atitle;
    titleEl.style.cssText = "margin:0 0 10px 0;font-size:1.5rem;color:#333;";

    const subtitleEl = document.createElement("p");
    subtitleEl.textContent = subtitle;
    subtitleEl.style.cssText = "margin:0 0 16px 0;color:#555;";

    const textArea = document.createElement("textarea");
    textArea.value = input;
    textArea.placeholder = "Paste your save data here...";
    textArea.style.cssText = "width:100%;height:120px;padding:10px 12px;border:1px solid #ccc;border-radius:8px;font-size:0.95rem;resize:none;box-sizing:border-box;";

    const buttonEl = document.createElement("button");
    buttonEl.textContent = button;
    buttonEl.style.cssText = "margin-top:16px;padding:10px 20px;font-size:1rem;background:#4CAF50;color:white;border:none;border-radius:8px;cursor:pointer;transition:background 0.2s;";

    const cleanup = () => {
        buttonEl.onmouseover = buttonEl.onmouseout = buttonEl.onclick = null;
        modal.remove();
    };

    buttonEl.onclick = () => {
        window.globalTextAreaResult = textArea.value.trim();
        cleanup();
    };
    buttonEl.onmouseover = () => buttonEl.style.backgroundColor = "#45a049";
    buttonEl.onmouseout  = () => buttonEl.style.backgroundColor = "#4CAF50";

    content.append(titleEl, subtitleEl, textArea, buttonEl);
    modal.appendChild(content);
    document.body.appendChild(modal);
}

// Example usage
showTextModal({
    input: "",
    atitle: "Import Save Data",
    subtitle: "Paste your save string into the field below, then press Import.",
    button: "Import Save"
});