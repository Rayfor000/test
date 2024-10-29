// 全局設置
const GLOBAL_CONFIG = {
	// 是否啟用請求計數
	ENABLE_REQUEST_COUNT: true,
	// 允許訪問的國家列表（白名單）(高優先級)
	ALLOWED_COUNTRIES: ['TW'], // 設為空字符串表示不使用
	// 被禁止訪問的國家列表（黑名單）(低優先級)(TW還是可以訪問)
	BLOCKED_COUNTRIES: ['CN', 'TW'],// 設為空字符串表示不使用
	// 允許的網域前綴列表
	ALLOWED_DOMAIN_PREFIXES: [
		'https://raw.githubusercontent.com/OG-Open-Source'// 設為空字符串表示不使用
	],
	// 允許的通用字段 (指連結必須包含此字段)
	ALLOWED_GENERAL_PATTERN: '', // 設為空字符串表示不使用
	// 新增配置項
	MAX_REQUESTS_PER_MINUTE: 60, // 每分鐘最大請求次數
	BLOCK_DURATION: 5 * 60, // 封鎖時間（秒），這裡設置為 5 分鐘
};

// KV 命名空間綁定(需設定KV並綁定到當前的Worker，如果沒有則跳過)
const REQUEST_COUNTER = typeof COUNTER_NAMESPACE !== 'undefined' ? COUNTER_NAMESPACE : {
	get: async () => null,
	put: async () => {},
	delete: async () => {}
};

addEventListener('fetch', event => {
	event.respondWith(handleRequest(event.request))
})

async function handleRequest(request) {
	// 檢查國家限制
	const country = request.cf.country;
	if (!isAllowedCountry(country)) {
		return new Response('Access denied: Your country is not allowed to use this proxy.', { status: 403 })
	}

	// 檢查請求頻率
	const clientIP = request.headers.get('CF-Connecting-IP');
	if (await isRateLimited(clientIP)) {
		return new Response('Too many requests. Please try again later.', { status: 429 });
	}

	const url = new URL(request.url);

	// 檢查路徑是否以 http:// 或 https:// 開頭
	const match = url.pathname.match(/^\/(https?:\/\/.+)/)

	if (!match) {
		return new Response('Invalid URL format.', { status: 400 })
	}

	// 提取目標 URL
	const targetUrl = match[1]

	// 檢查允許的域名和通用字段
	if (!isAllowedUrl(targetUrl)) {
		return new Response('Access denied: The requested URL is not allowed.', { status: 403 })
	}

	// 創建目標 URL 對象
	const destinationURL = new URL(targetUrl)
	destinationURL.pathname += url.pathname.slice(match[0].length)
	destinationURL.search = url.search

	// 創建一個新的請求對象
	let newRequest = new Request(destinationURL, request)

	// 非阻塞的請求計數增加
	if (GLOBAL_CONFIG.ENABLE_REQUEST_COUNT) {
		incrementRequestCount().catch(console.error);
	}

	// 發送請求到目標網站
	let response = await fetch(newRequest)

	// 創建一個新的響應對象並添加 CORS 頭
	let newResponse = new Response(response.body, response)
	newResponse.headers.set('Access-Control-Allow-Origin', '*')

	return newResponse
}

function isAllowedCountry(country) {
	if (GLOBAL_CONFIG.ALLOWED_COUNTRIES.length > 0) {
		return GLOBAL_CONFIG.ALLOWED_COUNTRIES.includes(country);
	} else {
		return !GLOBAL_CONFIG.BLOCKED_COUNTRIES.includes(country);
	}
}

function isAllowedUrl(url) {
	// 首先檢查 ALLOWED_DOMAIN_PREFIXES
	const isPrefixAllowed = GLOBAL_CONFIG.ALLOWED_DOMAIN_PREFIXES.some(prefix => url.startsWith(prefix));

	if (!isPrefixAllowed) {
		return false;
	}

	// 如果 ALLOWED_GENERAL_PATTERN 不為空，則進一步檢查
	if (GLOBAL_CONFIG.ALLOWED_GENERAL_PATTERN) {
		return url.includes(GLOBAL_CONFIG.ALLOWED_GENERAL_PATTERN);
	}

	// 如果 ALLOWED_GENERAL_PATTERN 為空，則只要 ALLOWED_DOMAIN_PREFIXES 通過就允許
	return true;
}

async function incrementRequestCount() {
	const currentDate = new Date().toISOString().split('T')[0];
	const countKey = `count_${currentDate}`;

	let count = await REQUEST_COUNTER.get(countKey) || '0';
	await REQUEST_COUNTER.put(countKey, (parseInt(count) + 1).toString());

	// 非阻塞的清理昨天的記錄
	const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
	REQUEST_COUNTER.delete(`count_${yesterday}`).catch(console.error);
}

async function isRateLimited(clientIP) {
	const now = Date.now();
	const minuteKey = `${clientIP}_${Math.floor(now / 60000)}`;
	const blockKey = `${clientIP}_blocked`;

	// 檢查是否被封鎖
	const blockedUntil = await REQUEST_COUNTER.get(blockKey);
	if (blockedUntil && parseInt(blockedUntil) > now) {
		return true;
	}

	// 增加請求計數
	let count = await REQUEST_COUNTER.get(minuteKey) || '0';
	count = parseInt(count) + 1;
	await REQUEST_COUNTER.put(minuteKey, count.toString(), { expirationTtl: 60 });

	// 檢查是否超過限制
	if (count > GLOBAL_CONFIG.MAX_REQUESTS_PER_MINUTE) {
		const blockUntil = now + GLOBAL_CONFIG.BLOCK_DURATION * 1000;
		await REQUEST_COUNTER.put(blockKey, blockUntil.toString(), { expirationTtl: GLOBAL_CONFIG.BLOCK_DURATION });
		return true;
	}

	return false;
}