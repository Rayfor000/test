from flask import Flask, request, jsonify
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
import re

app = Flask(__name__)

# 初始化 Limiter
limiter = Limiter(key_func=get_remote_address, app=app)

# 檢查 IP 地址格式，支持 IPv4 和 IPv6
def is_valid_ip(ip):
	ipv4_pattern = re.compile(r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$')
	ipv6_pattern = re.compile(r'^[a-fA-F0-9:]+$')

	if ipv4_pattern.match(ip):  # 檢查 IPv4
		return True
	if ipv6_pattern.match(ip):  # 檢查 IPv6
		# 進一步檢查 IPv6 格式是否正確
		try:
			import ipaddress
			ipaddress.IPv6Address(ip)  # 檢查是否是有效的 IPv6 地址
			return True
		except ipaddress.AddressValueError:
			return False
	return False

# 檢查 UUID 和 IP 的唯一性
def check_uuid_ip(uuid, ip):
	existing_ips = []
	try:
		with open('records.txt', 'r') as f:
			for line in f:
				record_uuid, record_ip = line.strip().split(", ")
				record_uuid = record_uuid.split(": ")[1]  # 取得 UUID
				record_ip = record_ip.split(": ")[1]      # 取得 IP
				if record_uuid == uuid:
					existing_ips.append(record_ip)  # 保存相同 UUID 的所有 IP
					if record_ip == ip:
						return 'exists'  # UUID 和 IP 皆存在
	except FileNotFoundError:
		return 'new'  # 文件不存在，視為新數據
	return 'different_ip' if existing_ips else 'new'  # 如果 UUID 存在但 IP 不同

# 註冊路由
@app.route('/register', methods=['POST'])
@limiter.limit("5 per minute")  # 每個 IP 每分鐘最多 5 次請求
def register():
	data = request.json
	uuid = data.get('uuid')
	ip = data.get('ip')

	if not uuid or not uuid.strip():
		return jsonify({'status': 'error', 'message': 'UUID cannot be empty.'}), 400

	if not is_valid_ip(ip):
		return jsonify({'status': 'error', 'message': 'Invalid IP address.'}), 400

	uuid_status = check_uuid_ip(uuid, ip)

	if uuid_status == 'exists':
		return jsonify({'status': 'success', 'message': 'UUID and IP already exist.', 'uuid': uuid, 'ip': ip})

	if uuid_status == 'different_ip':
		# UUID 已存在但 IP 不同，檢查是否已經記錄過此 IP
		with open('records.txt', 'r') as f:
			for line in f:
				record_uuid, record_ip = line.strip().split(", ")
				record_uuid = record_uuid.split(": ")[1]  # 取得 UUID
				record_ip = record_ip.split(": ")[1]      # 取得 IP
				if record_uuid == uuid and record_ip == ip:
					return jsonify({'status': 'success', 'message': 'UUID and IP already exist.', 'uuid': uuid, 'ip': ip})

		# 將 UUID 和 IP 寫入文件
		with open('records.txt', 'a') as f:
			f.write(f"UUID: {uuid}, IP: {ip}\n")
		return jsonify({'status': 'success', 'message': 'UUID exists with a different IP, added new IP.', 'uuid': uuid, 'ip': ip})

	# 將 UUID 和 IP 寫入文件
	with open('records.txt', 'a') as f:
		f.write(f"UUID: {uuid}, IP: {ip}\n")

	print(f"Received UUID: {uuid}, IP: {ip}")
	return jsonify({'status': 'success', 'uuid': uuid, 'ip': ip})

if __name__ == '__main__':
	app.run(host='0.0.0.0', port=5000)
