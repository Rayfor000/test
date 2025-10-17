document.addEventListener('DOMContentLoaded', () => {
    const textInput = document.getElementById('text-input');
    const regexInput = document.getElementById('regex-input');
    const highlightOutput = document.getElementById('highlight-output');
    const regexError = document.getElementById('regex-error');
    const popupButton = document.getElementById('popup-button');
    const modalContainer = document.getElementById('modal-container');
    const modalConfirm = document.getElementById('modal-confirm');
    const modalCancel = document.getElementById('modal-cancel');
    const customCharsInput = document.getElementById('custom-chars');
    const charSetCheckboxes = document.querySelectorAll('.char-sets input[type="checkbox"]');

    let currentSelection = ''; // To store the selected text for later use

    // --- Core Highlighting Logic ---
    function updateHighlight() {
        const sourceText = textInput.innerText;
        const regexPattern = regexInput.value;

        // Sync text-input's content to highlight-output's content
        // We use innerText to avoid injecting HTML into the output from the source
        highlightOutput.innerText = sourceText;
        regexError.textContent = ''; // Clear previous errors

        if (!regexPattern) {
            return; // Don't do anything if regex is empty
        }

        try {
            // 'g' for global search, 's' (dotAll) to make '.' match newlines, as per requirements
            const regex = new RegExp(regexPattern, 'gs');

            // To avoid infinite loops with zero-width matches, we can add a check,
            // but for now, the standard replace should handle most cases.
            // We replace matches with a <mark> tag to highlight them.
            const highlightedText = sourceText.replace(regex, (match) => `<mark>${match}</mark>`);

            highlightOutput.innerHTML = highlightedText;

        } catch (e) {
            // Display a user-friendly error message if the regex is invalid
            regexError.textContent = e.message;
            // Keep the output showing the plain text if regex is broken
            highlightOutput.innerText = sourceText;
        }
    }

    // --- Event Listeners ---
    textInput.addEventListener('input', updateHighlight);
    regexInput.addEventListener('input', updateHighlight);

    // --- Initial Placeholder Handling ---
    textInput.addEventListener('focus', () => {
        if (textInput.textContent === '請在此貼上您的範例文字...') {
            textInput.textContent = '';
        }
    });

    textInput.addEventListener('blur', () => {
        if (textInput.textContent.trim() === '') {
            textInput.textContent = '請在此貼上您的範例文字...';
        }
    });

    // --- Popup Button Logic ---
    textInput.addEventListener('mouseup', (e) => {
        // Use a slight timeout to let the browser register the selection
        setTimeout(() => {
            const selection = window.getSelection();
            const selectedText = selection.toString();

            if (selectedText.trim().length > 0) {
                currentSelection = selectedText; // Store the selection
                const range = selection.getRangeAt(0);
                const rect = range.getBoundingClientRect();

                // Position the popup near the end of the selection.
                // We use pageXOffset and pageYOffset to account for scrolling.
                const popupLeft = window.pageXOffset + rect.left + (rect.width / 2) - (popupButton.offsetWidth / 2);
                const popupTop = window.pageYOffset + rect.bottom + 5; // 5px below selection

                popupButton.style.left = `${popupLeft}px`;
                popupButton.style.top = `${popupTop}px`;
                popupButton.style.display = 'block';
            }
            // If no text is selected, the general mousedown listener will hide it.
        }, 10);
    });

    // Hide popup when clicking anywhere else on the page, except on the popup itself
    document.addEventListener('mousedown', (e) => {
        // If the click is outside the text input area and also not on the popup, hide it.
        if (!textInput.contains(e.target) && !popupButton.contains(e.target)) {
            popupButton.style.display = 'none';
        }
        // If the click is inside the text input but doesn't result in a selection,
        // the mouseup event won't fire to show it, and if it was already visible,
        // this new mousedown might precede a new selection, so we don't hide it here.
    });

    // --- Modal Logic ---
    function openModal() {
        // Reset modal state before showing
        customCharsInput.value = '';
        charSetCheckboxes.forEach(checkbox => checkbox.checked = false);
        modalContainer.style.display = 'flex';
    }

    function closeModal() {
        modalContainer.style.display = 'none';
    }

    // When "建立捕捉籠" is clicked, open the modal
    popupButton.querySelector('button').addEventListener('click', () => {
        popupButton.style.display = 'none'; // Hide the small button
        openModal();
    });

    // Modal action listeners
    modalCancel.addEventListener('click', closeModal);

    modalConfirm.addEventListener('click', () => {
        generateRegex();
        closeModal();
    });

    // --- Core Regex Generation Logic ---
    function generateRegex() {
        // 1. Get selected character sets from the modal
        let charSet = '';
        charSetCheckboxes.forEach(checkbox => {
            if (checkbox.checked) {
                charSet += checkbox.dataset.charSet;
            }
        });
        const customChars = customCharsInput.value;
        // Escape special characters in custom input for use in character set `[]`
        const escapedCustomChars = customChars.replace(/[\\\]-]/g, '\\$&');
        charSet += escapedCustomChars;

        // If no character set is selected, default to `.` to match any character (except newline)
        // The 's' flag on the final regex will make `.` match newlines too.
        if (charSet.length === 0) {
            charSet = '.';
        }

        // 2. Determine the boundaries from the user's selection
        let { start, end } = findBoundaries(currentSelection);


        // 3. Escape the boundaries for use in the regex
        const escapedStart = escapeRegex(start);
        const escapedEnd = escapeRegex(end);

        // 4. Construct the final regex
        // If the character set is a single dot, we don't need to wrap it in `[]`.
        const captureContent = (charSet === '.') ? charSet : `[${charSet}]`;
        const finalRegex = `${escapedStart}(${captureContent}+?)${escapedEnd}`;

        // 5. Update the UI
        regexInput.value = finalRegex;
        updateHighlight(); // Trigger the highlight with the new regex
    }

    function escapeRegex(string) {
        // Escapes special characters for use in a new RegExp
        return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // $& means the whole matched string
    }

    function findLastIndex(str, regex) {
        const match = str.match(new RegExp(`.*(${regex.source})`, 's'));
        return match ? str.lastIndexOf(match[1]) : -1;
    }

    function findBoundaries(text) {
        const pairs = { '(': ')', '{': '}', '[': ']', '<': '>', '"': '"', "'": "'" };
        const openDelimiters = Object.keys(pairs);

        let firstOpenIndex = -1;
        for (let i = 0; i < text.length; i++) {
            if (openDelimiters.includes(text[i])) {
                firstOpenIndex = i;
                break;
            }
        }

        if (firstOpenIndex === -1) {
            // If no delimiter is found, fallback to first/last character.
            return { start: text.charAt(0), end: text.charAt(text.length - 1) };
        }

        const startBoundary = text.substring(0, firstOpenIndex + 1);
        const expectedClose = pairs[text[firstOpenIndex]];

        let lastCloseIndex = -1;
        for (let i = text.length - 1; i > firstOpenIndex; i--) {
            if (text[i] === expectedClose) {
                lastCloseIndex = i;
                break;
            }
        }

        if (lastCloseIndex === -1) {
            // If no matching closing delimiter found, fallback to the last character.
            return { start: startBoundary, end: text.charAt(text.length - 1) };
        }

        const endBoundary = text.substring(lastCloseIndex);
        return { start: startBoundary, end: endBoundary };
    }


    // --- Initial call to set the state ---
    // This ensures the output is populated with the initial placeholder text
    updateHighlight();
});