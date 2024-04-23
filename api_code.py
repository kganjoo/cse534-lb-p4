# app.py
import sys
sys.path.append('/home/ubuntu/flask/lib/python3.8/site-packages')
from flask import Flask, jsonify
import asyncio

app = Flask(__name__)

async def async_task():
    # Simulating an asynchronous task
    await asyncio.sleep(2)
    return "Async task completed"

@app.route('/async', methods=['GET'])
async def async_endpoint():
    result = await async_task()
    return jsonify(message=result)

if __name__ == '__main__':
    app.run(host='192.168.2.10', port=80)