// app.js v3.0.0a1-9

// CONFIG
const BASE_URL = "";
const DATA_PATH = "data";
const IMG_PATH = "img";
const MAX_COST = 12;

// STATE
let state = {
	lang: "TC",
	resonators: {},
	weapons: {},
	echoes: {},
	growthTable: {},
	savedBuilds: [],
	currentBuild: {
		charId: null,
		weaponId: null,
		echoes: [
			{ id: null, mainStat: null, subStats: [null, null, null, null, null] },
			{ id: null, mainStat: null, subStats: [null, null, null, null, null] },
			{ id: null, mainStat: null, subStats: [null, null, null, null, null] },
			{ id: null, mainStat: null, subStats: [null, null, null, null, null] },
			{ id: null, mainStat: null, subStats: [null, null, null, null, null] }
		]
	},
	currentPage: "page-dashboard",
	filters: {
		char: { rarity: "all", attr: "" },
		weapon: { rarity: "all" },
		echo: { cost: "all", sonata: "" }
	},
	activeStatBtn: { row: 0, idx: 0 }
};

// MAIN STAT OPTIONS BY COST
const MAIN_STATS = {
	"1": ["00184", "00185", "00183"],
	"3": ["00184", "00185", "00183", "00186", "00187", "00188"],
	"4": ["00184", "00185", "00183", "00186", "00187", "00188", "11", "12"]
};

const SUB_STATS = ["01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13"];

// ATOMIC: Data Fetching
async function loadData(lang) {
	try {
		// Try bundle first, fallback to separate files
		let res, weap, echo;
		try {
			const bundle = await fetch(`${BASE_URL}dist/bundle_${lang}.json`).then(r => r.json());
			res = bundle.resonators;
			weap = bundle.weapons;
			echo = bundle.echoes;
		} catch (bundleErr) {
			// Fallback to separate files
			[res, weap, echo] = await Promise.all([
				fetch(`${BASE_URL}${DATA_PATH}/${lang}/resonators.json`).then(r => r.json()),
				fetch(`${BASE_URL}${DATA_PATH}/${lang}/weapons.json`).then(r => r.json()),
				fetch(`${BASE_URL}${DATA_PATH}/${lang}/echoes.json`).then(r => r.json())
			]);
		}
		const growth = await fetch(`${BASE_URL}growth_table.json`).then(r => r.json());
		state.resonators = res;
		state.weapons = weap;
		state.echoes = echo;
		state.growthTable = growth;
		loadSavedBuilds();
		return true;
	} catch (e) {
		console.error("Data load failed", e);
		return false;
	}
}

// ATOMIC: LocalStorage
function loadSavedBuilds() {
	try {
		const saved = localStorage.getItem("wuwa_builds");
		if (saved) {
			state.savedBuilds = JSON.parse(saved);
		}
	} catch (e) {
		state.savedBuilds = [];
	}
}

function saveBuilds() {
	try {
		localStorage.setItem("wuwa_builds", JSON.stringify(state.savedBuilds));
	} catch (e) {
		console.error("Failed to save builds", e);
	}
}

// ATOMIC: Page Navigation
function showPage(pageId) {
	document.querySelectorAll(".page").forEach(p => p.classList.remove("active"));
	document.getElementById(pageId).classList.add("active");
	state.currentPage = pageId;
}

// ATOMIC: Cost Calculation
function calculateTotalCost() {
	return state.currentBuild.echoes.reduce((sum, echo) => {
		if (!echo.id) return sum;
		const echoData = state.echoes[echo.id];
		if (!echoData) return sum;
		const cost = parseInt(echoData.Cost.replace(/[^0-9]/g, "")) || 0;
		return sum + cost;
	}, 0);
}

function getEchoCost(echoId) {
	if (!echoId) return 0;
	const echoData = state.echoes[echoId];
	if (!echoData) return 0;
	return parseInt(echoData.Cost.replace(/[^0-9]/g, "")) || 0;
}

function getRemainingCost() {
	return MAX_COST - calculateTotalCost();
}

// RENDER: Dashboard
function renderDashboard() {
	const grid = document.getElementById("dashboard-grid");

	if (state.savedBuilds.length === 0) {
		grid.innerHTML = `
			<div class="empty-state">
				<div class="empty-icon"><i data-lucide="clipboard-list"></i></div>
				<p>尚無配置</p>
				<span>點擊右上角新增配置開始</span>
			</div>
		`;
		if (typeof lucide !== "undefined") lucide.createIcons();
		return;
	}

	grid.innerHTML = "";
	state.savedBuilds.forEach((build, idx) => {
		const char = state.resonators[build.charId];
		if (!char) return;

		const card = document.createElement("div");
		card.className = "build-card";
		card.innerHTML = `
			<div class="char-section">
				<img class="char-thumb" src="${BASE_URL}${char.Icon}" alt="${char.Name}" />
				<div class="char-info">
					<div class="char-name">${char.Name}</div>
					<div class="char-attrs">
						<img class="attr-icon-small" src="${BASE_URL}${char.AttributeIcon}" alt="" />
						<img class="attr-icon-small" src="${BASE_URL}${char.WeaponTypeIcon}" alt="" />
					</div>
				</div>
			</div>
			<div class="score-section">
				<div>
					<div class="score-label">評分</div>
					<div class="echo-preview">
						${build.echoes.filter(e => e.id).map(e => {
							const echoData = state.echoes[e.id];
							return echoData ? `<img src="${BASE_URL}${echoData.Icon}" alt="" />` : "";
						}).join("")}
					</div>
				</div>
				<div class="score-value">${build.score || "--"}</div>
			</div>
		`;
		card.addEventListener("click", () => loadBuild(idx));
		grid.appendChild(card);
	});
}

// RENDER: Character Grid with Filters
function renderCharGrid() {
	const grid = document.getElementById("char-grid");
	grid.innerHTML = "";

	let chars = Object.entries(state.resonators);

	// Apply filters
	if (state.filters.char.rarity !== "all") {
		const targetRarity = state.filters.char.rarity === "5" ? "五星" : "四星";
		chars = chars.filter(([id, data]) => data.Rarity === targetRarity);
	}

	if (state.filters.char.attr) {
		chars = chars.filter(([id, data]) => data.Attribute === state.filters.char.attr);
	}

	// Sort by ID (descending - larger ID first)
	chars.sort((a, b) => parseInt(b[0]) - parseInt(a[0]));

	chars.forEach(([id, data]) => {
		const isSelected = state.currentBuild.charId === id;
		const card = document.createElement("div");
		card.className = "char-card" + (isSelected ? " selected" : "");
		card.dataset.id = id;

		let actionsHtml = "";
		if (isSelected) {
			actionsHtml = `
				<div class="card-actions">
					<button class="btn-action" data-action="weapon"><i data-lucide="sword"></i> 武器</button>
					<button class="btn-action" data-action="echo"><i data-lucide="circle-dot"></i> 聲骸</button>
				</div>
			`;
		}

		card.innerHTML = `
			<img class="card-bg" src="${BASE_URL}img/card.png" alt="" />
			<img class="char-img" src="${BASE_URL}${data.Icon}" alt="${data.Name}" />
			<img class="attr-badge" src="${BASE_URL}${data.AttributeIcon}" alt="" />
			<img class="rarity-icon" src="${BASE_URL}${data.RarityIcon}" alt="" />
			<span class="char-name">${data.Name}</span>
			${actionsHtml}
		`;

		card.addEventListener("click", (e) => {
			if (e.target.closest(".btn-action")) {
				const action = e.target.closest(".btn-action").dataset.action;
				if (action === "weapon") {
					renderWeaponGrid();
					showPage("page-weapon");
				} else if (action === "echo") {
					renderEchoGrid();
					renderEchoSlots();
					showPage("page-echo-select");
				}
			} else {
				selectCharacter(id);
			}
		});
		grid.appendChild(card);
	});

	if (typeof lucide !== "undefined") lucide.createIcons();
}

// RENDER: Weapon Grid with Filters
function renderWeaponGrid() {
	const grid = document.getElementById("weapon-grid");
	grid.innerHTML = "";

	const char = state.resonators[state.currentBuild.charId];
	if (!char) return;

	let weapons = Object.entries(state.weapons).filter(([id, data]) => {
		// Filter by weapon type matching character
		return data.Type === char.WeaponType;
	});

	// Apply rarity filter
	if (state.filters.weapon.rarity !== "all") {
		const targetRarity = state.filters.weapon.rarity === "5" ? "5星" : "4星";
		weapons = weapons.filter(([id, data]) => data.Rarity === targetRarity);
	}

	weapons.forEach(([id, data]) => {
		const card = document.createElement("div");
		card.className = "weapon-card";
		if (state.currentBuild.weaponId === id) card.classList.add("selected");
		card.dataset.id = id;

		card.innerHTML = `
			<img src="${BASE_URL}${data.Icon}" alt="${data.Name}" />
			<div class="weapon-name">${data.Name}</div>
		`;

		card.addEventListener("click", () => selectWeapon(id));
		grid.appendChild(card);
	});
}

// RENDER: Selected Character Preview
function renderCharPreview() {
	const char = state.resonators[state.currentBuild.charId];
	if (!char) return;

	// Weapon page preview
	const weaponPreview = document.getElementById("char-preview-weapon");
	if (weaponPreview) {
		weaponPreview.querySelector(".char-img").src = BASE_URL + char.Icon;
		weaponPreview.querySelector(".attr-icon").src = BASE_URL + char.AttributeIcon;
		weaponPreview.querySelector(".rarity-icon").src = BASE_URL + char.RarityIcon;
	}

	// Echo page preview
	const echoPreview = document.getElementById("char-preview-echo");
	if (echoPreview) {
		echoPreview.querySelector(".char-img").src = BASE_URL + char.Icon;
		echoPreview.querySelector(".attr-icon").src = BASE_URL + char.AttributeIcon;
	}
}

// RENDER: Weapon Thumb
function renderWeaponThumb() {
	const thumb = document.getElementById("weapon-thumb");
	if (!thumb) return;

	const weapon = state.weapons[state.currentBuild.weaponId];
	if (weapon) {
		thumb.querySelector("img").src = BASE_URL + weapon.Icon;
		thumb.style.display = "flex";
	} else {
		thumb.style.display = "none";
	}
}

// RENDER: Echo Select Grid with Filters
function renderEchoGrid() {
	const grid = document.getElementById("echo-select-grid");
	grid.innerHTML = "";

	const remainingCost = getRemainingCost();
	const selectedIds = state.currentBuild.echoes.map(e => e.id);

	// Populate sonata filter if empty
	const sonataSelect = document.getElementById("sonata-filter");
	if (sonataSelect && sonataSelect.options.length <= 1) {
		const sonatas = new Set();
		Object.values(state.echoes).forEach(echo => {
			echo.SonataGroup?.forEach(s => sonatas.add(s.Val));
		});
		Array.from(sonatas).sort().forEach(sonata => {
			const opt = document.createElement("option");
			opt.value = sonata;
			opt.textContent = sonata;
			sonataSelect.appendChild(opt);
		});
	}

	let echoes = Object.entries(state.echoes);

	// Apply filters
	if (state.filters.echo.cost !== "all") {
		echoes = echoes.filter(([id, data]) => {
			const cost = parseInt(data.Cost.replace(/[^0-9]/g, "")) || 0;
			return cost === parseInt(state.filters.echo.cost);
		});
	}

	if (state.filters.echo.sonata) {
		echoes = echoes.filter(([id, data]) => {
			return data.SonataGroup?.some(s => s.Val === state.filters.echo.sonata);
		});
	}

	echoes.forEach(([id, data]) => {
		const cost = parseInt(data.Cost.replace(/[^0-9]/g, "")) || 0;

		const item = document.createElement("div");
		item.className = "echo-item";
		item.dataset.id = id;

		if (selectedIds.includes(id)) {
			item.classList.add("selected");
		}

		if (!selectedIds.includes(id) && cost > remainingCost) {
			item.classList.add("disabled");
		}

		item.innerHTML = `
			<img src="${BASE_URL}${data.Icon}" alt="${data.Name}" />
			<span class="echo-cost-badge">${data.Cost.replace("COST ", "")}</span>
		`;

		item.addEventListener("mouseenter", (e) => showTooltip(e, id));
		item.addEventListener("mouseleave", hideTooltip);
		item.addEventListener("mousemove", moveTooltip);

		if (!item.classList.contains("disabled")) {
			item.addEventListener("click", () => toggleEchoSelection(id));
		}

		grid.appendChild(item);
	});
}

// RENDER: Echo Slots
function renderEchoSlots() {
	const slots = document.querySelectorAll(".echo-slot-circle");

	slots.forEach((slot, idx) => {
		const echo = state.currentBuild.echoes[idx];
		const img = slot.querySelector(".slot-img");
		const cost = slot.querySelector(".slot-cost");

		if (echo.id) {
			const echoData = state.echoes[echo.id];
			slot.classList.add("filled");
			img.src = BASE_URL + echoData.Icon;
			cost.textContent = echoData.Cost.replace("COST ", "");
		} else {
			slot.classList.remove("filled");
			img.src = "";
			cost.textContent = "";
		}
	});

	const totalCost = calculateTotalCost();
	const costEl = document.getElementById("total-cost");
	costEl.textContent = totalCost;
	costEl.classList.toggle("overlimit", totalCost > MAX_COST);
}

// RENDER: Echo Config List
function renderEchoConfigList() {
	const list = document.getElementById("echo-config-list");
	list.innerHTML = "";

	state.currentBuild.echoes.forEach((echo, rowIdx) => {
		const row = document.createElement("div");
		row.className = "echo-config-row";
		if (!echo.id) row.classList.add("empty");

		if (!echo.id) {
			row.innerHTML = `<span class="empty-slot">空位 ${rowIdx + 1} - 請先選擇聲骸</span>`;
			list.appendChild(row);
			return;
		}

		const echoData = state.echoes[echo.id];
		const sonataIcon = echoData.SonataGroup?.[0]?.Icon || "";

		let statButtonsHtml = "";
		for (let i = 0; i < 6; i++) {
			const isMain = i === 0;
			const isActive = state.activeStatBtn.row === rowIdx && state.activeStatBtn.idx === i;
			const isFilled = isMain ? echo.mainStat : echo.subStats[i - 1];
			const btnClass = `stat-btn ${isMain ? "main-stat" : ""} ${isActive ? "active" : ""} ${isFilled ? "filled" : ""}`;
			const btnText = isMain ? "主" : i;
			statButtonsHtml += `<button class="${btnClass}" data-row="${rowIdx}" data-idx="${i}">${btnText}</button>`;
		}

		const cost = getEchoCost(echo.id);
		const mainOptions = MAIN_STATS[cost] || [];

		const isMainActive = state.activeStatBtn.row === rowIdx && state.activeStatBtn.idx === 0;
		const activeSubIdx = state.activeStatBtn.row === rowIdx && state.activeStatBtn.idx > 0 ? state.activeStatBtn.idx - 1 : -1;

		let statSelectsHtml = `
			<select class="stat-select" id="stat-type-${rowIdx}" ${!isMainActive && activeSubIdx < 0 ? "disabled" : ""}>
				<option value="">選擇屬性</option>
			`;

		if (isMainActive) {
			mainOptions.forEach(opt => {
				const selected = echo.mainStat?.type === opt ? "selected" : "";
				statSelectsHtml += `<option value="${opt}" ${selected}>${getStatName(opt)}</option>`;
			});
		} else if (activeSubIdx >= 0) {
			SUB_STATS.forEach(opt => {
				const selected = echo.subStats[activeSubIdx]?.type === opt ? "selected" : "";
				statSelectsHtml += `<option value="${opt}" ${selected}>${getStatName(opt)}</option>`;
			});
		}
		statSelectsHtml += `</select>`;

		const currentValue = isMainActive ? echo.mainStat?.value : (activeSubIdx >= 0 ? echo.subStats[activeSubIdx]?.value : null);
		statSelectsHtml += `
			<select class="stat-select" id="stat-value-${rowIdx}" ${!currentValue ? "disabled" : ""}>
				<option value="">數值</option>
			</select>
		`;

		row.innerHTML = `
			<div class="echo-info-vertical">
				<img class="echo-thumb" src="${BASE_URL}${echoData.Icon}" alt="" />
				<span class="echo-cost-v">${echoData.Cost.replace("COST ", "")}</span>
				${sonataIcon ? `<img class="sonata-icon" src="${BASE_URL}${sonataIcon}" alt="" />` : ""}
			</div>
			<div class="stat-buttons">
				${statButtonsHtml}
			</div>
			<div class="stat-selects">
				${statSelectsHtml}
			</div>
		`;

		list.appendChild(row);
	});

	attachConfigListeners();
}

// ATOMIC: Get Stat Name
function getStatName(statId) {
	const statNames = {
		"01": "生命",
		"02": "攻擊",
		"03": "防禦",
		"04": "生命%",
		"05": "攻擊%",
		"06": "防禦%",
		"07": "暴擊率",
		"08": "暴擊傷害",
		"09": "共鳴效率",
		"10": "普攻傷害",
		"11": "重擊傷害",
		"12": "共鳴技能",
		"13": "共鳴解放",
		"00184": "生命",
		"00185": "防禦",
		"00183": "攻擊",
		"00186": "共鳴效率",
		"00187": "暴擊率",
		"00188": "暴擊傷害"
	};
	return statNames[statId] || statId;
}

// ATOMIC: Attach Config Listeners
function attachConfigListeners() {
	document.querySelectorAll(".stat-btn").forEach(btn => {
		btn.addEventListener("click", () => {
			const row = parseInt(btn.dataset.row);
			const idx = parseInt(btn.dataset.idx);
			state.activeStatBtn = { row, idx };
			renderEchoConfigList();
		});
	});

	document.querySelectorAll("[id^='stat-type-']").forEach(select => {
		select.addEventListener("change", (e) => {
			const rowIdx = parseInt(select.id.split("-")[2]);
			const typeValue = e.target.value;

			if (!typeValue) return;

			const isMain = state.activeStatBtn.row === rowIdx && state.activeStatBtn.idx === 0;
			if (isMain) {
				state.currentBuild.echoes[rowIdx].mainStat = { type: typeValue, value: null };
			} else {
				const subIdx = state.activeStatBtn.idx - 1;
				state.currentBuild.echoes[rowIdx].subStats[subIdx] = { type: typeValue, value: null };
			}

			updateValueSelect(rowIdx, typeValue);
		});
	});

	document.querySelectorAll("[id^='stat-value-']").forEach(select => {
		select.addEventListener("change", (e) => {
			const rowIdx = parseInt(select.id.split("-")[2]);
			const value = e.target.value;

			if (!value) return;

			const isMain = state.activeStatBtn.row === rowIdx && state.activeStatBtn.idx === 0;
			if (isMain) {
				state.currentBuild.echoes[rowIdx].mainStat.value = value;
			} else {
				const subIdx = state.activeStatBtn.idx - 1;
				state.currentBuild.echoes[rowIdx].subStats[subIdx].value = value;
			}

			autoAdvanceStatBtn(rowIdx);
			renderEchoConfigList();
		});
	});
}

// ATOMIC: Update Value Select
function updateValueSelect(rowIdx, typeValue) {
	const valueSelect = document.getElementById(`stat-value-${rowIdx}`);
	if (!valueSelect) return;

	valueSelect.innerHTML = '<option value="">數值</option>';
	valueSelect.disabled = false;

	const isMain = state.activeStatBtn.row === rowIdx && state.activeStatBtn.idx === 0;
	const values = isMain ? ["固定值"] : (state.growthTable.stats[typeValue] || []);

	values.forEach((val, idx) => {
		valueSelect.innerHTML += `<option value="${val}">${val}</option>`;
	});
}

// ATOMIC: Auto Advance Stat Button
function autoAdvanceStatBtn(currentRow) {
	const { row, idx } = state.activeStatBtn;
	if (row !== currentRow) return;

	let nextIdx = idx + 1;
	if (nextIdx >= 6) {
		let nextRow = row + 1;
		while (nextRow < 5 && !state.currentBuild.echoes[nextRow].id) {
			nextRow++;
		}
		if (nextRow < 5) {
			state.activeStatBtn = { row: nextRow, idx: 0 };
		}
	} else {
		state.activeStatBtn = { row, idx: nextIdx };
	}
}

// ATOMIC: Tooltip
function showTooltip(e, echoId) {
	const tooltip = document.getElementById("echo-tooltip");
	const echoData = state.echoes[echoId];
	if (!echoData) return;

	tooltip.querySelector(".tooltip-img").src = BASE_URL + echoData.Icon;
	tooltip.querySelector(".tooltip-name").textContent = echoData.Name;
	tooltip.querySelector(".tooltip-cost").textContent = echoData.Cost;

	const sonataNames = echoData.SonataGroup?.map(s => s.Val).join(", ") || "";
	tooltip.querySelector(".tooltip-sonata").textContent = sonataNames;

	tooltip.classList.remove("hidden");
	moveTooltip(e);
}

function hideTooltip() {
	document.getElementById("echo-tooltip").classList.add("hidden");
}

function moveTooltip(e) {
	const tooltip = document.getElementById("echo-tooltip");
	const x = e.clientX + 15;
	const y = e.clientY + 15;

	const rect = tooltip.getBoundingClientRect();
	const winW = window.innerWidth;
	const winH = window.innerHeight;

	let finalX = x;
	let finalY = y;

	if (x + rect.width > winW) finalX = x - rect.width - 15;
	if (y + rect.height > winH) finalY = y - rect.height - 15;

	tooltip.style.left = finalX + "px";
	tooltip.style.top = finalY + "px";
}

// ACTIONS
function startNewBuild() {
	state.currentBuild = {
		charId: null,
		weaponId: null,
		echoes: [
			{ id: null, mainStat: null, subStats: [null, null, null, null, null] },
			{ id: null, mainStat: null, subStats: [null, null, null, null, null] },
			{ id: null, mainStat: null, subStats: [null, null, null, null, null] },
			{ id: null, mainStat: null, subStats: [null, null, null, null, null] },
			{ id: null, mainStat: null, subStats: [null, null, null, null, null] }
		]
	};
	state.activeStatBtn = { row: 0, idx: 0 };
	renderCharGrid();
	showPage("page-char");
}

function selectCharacter(charId) {
	state.currentBuild.charId = charId;
	renderCharGrid();
	renderCharPreview();
	renderWeaponGrid();
}

function selectWeapon(weaponId) {
	state.currentBuild.weaponId = weaponId;
	renderWeaponGrid();
	renderWeaponThumb();
}

function toggleEchoSelection(echoId) {
	const existingIdx = state.currentBuild.echoes.findIndex(e => e.id === echoId);

	if (existingIdx >= 0) {
		state.currentBuild.echoes[existingIdx] = { id: null, mainStat: null, subStats: [null, null, null, null, null] };
	} else {
		const emptyIdx = state.currentBuild.echoes.findIndex(e => !e.id);
		if (emptyIdx >= 0) {
			state.currentBuild.echoes[emptyIdx] = { id: echoId, mainStat: null, subStats: [null, null, null, null, null] };
		}
	}

	renderEchoGrid();
	renderEchoSlots();
}

function saveCurrentBuild() {
	const score = calculateBuildScore();
	const build = {
		...state.currentBuild,
		score: score,
		timestamp: Date.now()
	};
	state.savedBuilds.push(build);
	saveBuilds();
	renderDashboard();
	showPage("page-dashboard");
}

function calculateBuildScore() {
	// Simple scoring logic - can be enhanced
	let score = 0;
	state.currentBuild.echoes.forEach(echo => {
		if (echo.id) score += 20;
		if (echo.mainStat) score += 10;
		echo.subStats.forEach(sub => {
			if (sub) score += 5;
		});
	});
	return Math.min(score, 100);
}

function loadBuild(idx) {
	const build = state.savedBuilds[idx];
	if (!build) return;
	state.currentBuild = JSON.parse(JSON.stringify(build));
	delete state.currentBuild.score;
	delete state.currentBuild.timestamp;
	renderEchoConfigList();
	showPage("page-echo-stats");
}

// EVENT HANDLERS
function attachEventListeners() {
	// Language switch
	document.querySelectorAll(".lang-switch button").forEach(btn => {
		btn.addEventListener("click", async () => {
			const lang = btn.dataset.lang;
			state.lang = lang;
			document.querySelectorAll(".lang-switch button").forEach(b => b.classList.remove("active"));
			btn.classList.add("active");
			await loadData(lang);
			// Re-render all visible pages
			renderDashboard();
			renderCharGrid();
			renderWeaponGrid();
			renderEchoGrid();
			renderEchoSlots();
			renderEchoConfigList();
			// Update selected previews
			renderCharPreview();
			renderWeaponThumb();
		});
	});

	// Dashboard
	document.getElementById("btn-new-build").addEventListener("click", startNewBuild);

	// Character filters
	document.querySelectorAll("#page-char .filter-tab").forEach(tab => {
		tab.addEventListener("click", () => {
			state.filters.char.rarity = tab.dataset.filter;
			document.querySelectorAll("#page-char .filter-tab").forEach(t => t.classList.remove("active"));
			tab.classList.add("active");
			renderCharGrid();
		});
	});

	document.getElementById("attr-filter").addEventListener("change", (e) => {
		state.filters.char.attr = e.target.value;
		renderCharGrid();
	});

	// Weapon filters
	document.querySelectorAll("#page-weapon .filter-tab").forEach(tab => {
		tab.addEventListener("click", () => {
			state.filters.weapon.rarity = tab.dataset.filter;
			document.querySelectorAll("#page-weapon .filter-tab").forEach(t => t.classList.remove("active"));
			tab.classList.add("active");
			renderWeaponGrid();
		});
	});

	// Echo filters
	document.querySelectorAll("#page-echo-select .filter-tab").forEach(tab => {
		tab.addEventListener("click", () => {
			state.filters.echo.cost = tab.dataset.cost;
			document.querySelectorAll("#page-echo-select .filter-tab").forEach(t => t.classList.remove("active"));
			tab.classList.add("active");
			renderEchoGrid();
		});
	});

	document.getElementById("sonata-filter").addEventListener("change", (e) => {
		state.filters.echo.sonata = e.target.value;
		renderEchoGrid();
	});

	// Navigation
	document.getElementById("btn-back-dashboard").addEventListener("click", () => showPage("page-dashboard"));
	document.getElementById("btn-back-char").addEventListener("click", () => showPage("page-char"));
	document.getElementById("btn-to-echo").addEventListener("click", () => {
		renderEchoGrid();
		renderEchoSlots();
		showPage("page-echo-select");
	});
	document.getElementById("btn-back-weapon").addEventListener("click", () => showPage("page-weapon"));
	document.getElementById("btn-to-stats").addEventListener("click", () => {
		state.activeStatBtn = { row: 0, idx: 0 };
		renderEchoConfigList();
		showPage("page-echo-stats");
	});
	document.getElementById("btn-back-echo").addEventListener("click", () => showPage("page-echo-select"));
	document.getElementById("btn-save-build").addEventListener("click", saveCurrentBuild);

	// Echo slot clicks (to remove)
	document.querySelectorAll(".echo-slot-circle").forEach(slot => {
		slot.addEventListener("click", () => {
			const idx = parseInt(slot.dataset.slot);
			if (state.currentBuild.echoes[idx].id) {
				state.currentBuild.echoes[idx] = { id: null, mainStat: null, subStats: [null, null, null, null, null] };
				renderEchoGrid();
				renderEchoSlots();
			}
		});
	});
}

// MAIN
async function main() {
	try {
		const ok = await loadData(state.lang);
		if (!ok) throw new Error("Initial load failed");

		renderDashboard();
		renderCharGrid();
		attachEventListeners();

		// Initialize Lucide icons
		if (typeof lucide !== "undefined") {
			lucide.createIcons();
		}

	} catch (e) {
		console.error("Main execution error", e);
	}
}

if (document.readyState === "loading") {
	document.addEventListener("DOMContentLoaded", main);
} else {
	main();
}
