from flask import Flask, jsonify, request

app = Flask(__name__)

@app.route('/init', methods=['POST'])
def wsk_init():
	return ''

@app.route('/run', methods=['POST'])
def wsk_run():
	params = request.get_json(force=True)
	# jsonify wraps json.dumps
	return jsonify(params)

app.run(host='0.0.0.0', port=8080)
