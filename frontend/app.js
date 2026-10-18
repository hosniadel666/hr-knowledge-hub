const API_URL = window.HR_HUB_CONFIG?.apiUrl || "";
let sessionId = null;

const chatContainer = document.getElementById("chatContainer");
const queryForm = document.getElementById("queryForm");
const queryInput = document.getElementById("queryInput");
const sendButton = document.getElementById("sendButton");

queryForm.addEventListener("submit", function (e) {
    e.preventDefault();
    const query = queryInput.value.trim();
    if (query) sendQuery(query);
});

function askSuggestion(button) {
    sendQuery(button.textContent);
}

async function sendQuery(query) {
    removeWelcome();
    appendMessage("user", query);
    queryInput.value = "";
    queryInput.disabled = true;
    sendButton.disabled = true;

    const loadingEl = appendLoading();

    try {
        const response = await fetch(API_URL + "/query", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ query: query, session_id: sessionId }),
        });

        const data = await response.json();
        loadingEl.remove();

        if (!response.ok) {
            appendMessage("assistant", "Sorry, something went wrong: " + (data.error || "Unknown error"));
            return;
        }

        sessionId = data.session_id;
        appendMessage("assistant", data.answer, data.citations);
    } catch (err) {
        loadingEl.remove();
        appendMessage("assistant", "Unable to reach the server. Please try again.");
    } finally {
        queryInput.disabled = false;
        sendButton.disabled = false;
        queryInput.focus();
    }
}

function removeWelcome() {
    const welcome = chatContainer.querySelector(".welcome-message");
    if (welcome) welcome.remove();
}

function appendMessage(role, text, citations) {
    const messageDiv = document.createElement("div");
    messageDiv.className = "message message-" + role;

    const avatar = document.createElement("div");
    avatar.className = "avatar avatar-" + role;
    avatar.textContent = role === "user" ? "You" : "AI";

    const bubble = document.createElement("div");
    bubble.className = "bubble bubble-" + role;
    bubble.textContent = text;

    if (role === "assistant" && citations && citations.length > 0) {
        const sources = extractSources(citations);
        if (sources.length > 0) {
            const citationsDiv = document.createElement("div");
            citationsDiv.className = "citations";

            const toggle = document.createElement("button");
            toggle.className = "citations-toggle";
            toggle.innerHTML = "&#9660; Sources (" + sources.length + ")";
            toggle.addEventListener("click", function () {
                const list = citationsDiv.querySelector(".citations-list");
                list.classList.toggle("open");
                toggle.innerHTML = list.classList.contains("open")
                    ? "&#9650; Sources (" + sources.length + ")"
                    : "&#9660; Sources (" + sources.length + ")";
            });

            const list = document.createElement("div");
            list.className = "citations-list";
            sources.forEach(function (src) {
                const item = document.createElement("div");
                item.className = "citation-item";
                item.textContent = src;
                list.appendChild(item);
            });

            citationsDiv.appendChild(toggle);
            citationsDiv.appendChild(list);
            bubble.appendChild(citationsDiv);
        }
    }

    messageDiv.appendChild(avatar);
    messageDiv.appendChild(bubble);
    chatContainer.appendChild(messageDiv);
    chatContainer.scrollTop = chatContainer.scrollHeight;
}

function appendLoading() {
    const messageDiv = document.createElement("div");
    messageDiv.className = "message message-assistant";

    const avatar = document.createElement("div");
    avatar.className = "avatar avatar-assistant";
    avatar.textContent = "AI";

    const bubble = document.createElement("div");
    bubble.className = "bubble bubble-assistant";

    const dots = document.createElement("div");
    dots.className = "loading-dots";
    dots.innerHTML = "<span></span><span></span><span></span>";
    bubble.appendChild(dots);

    messageDiv.appendChild(avatar);
    messageDiv.appendChild(bubble);
    chatContainer.appendChild(messageDiv);
    chatContainer.scrollTop = chatContainer.scrollHeight;
    return messageDiv;
}

function extractSources(citations) {
    const seen = new Set();
    const sources = [];
    citations.forEach(function (c) {
        (c.references || []).forEach(function (ref) {
            if (ref && !seen.has(ref)) {
                seen.add(ref);
                var name = ref.split("/").pop();
                sources.push(name);
            }
        });
    });
    return sources;
}
