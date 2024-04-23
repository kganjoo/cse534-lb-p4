# app.py
import sys
sys.path.append('/home/ubuntu/flask/lib/python3.8/site-packages')
from flask import Flask, jsonify

import multiprocessing

app = Flask(__name__)

def calculate_primes(start, end):
    primes = []
    for num in range(start, end + 1):
        if all(num % i != 0 for i in range(2, int(num ** 0.5) + 1)):
            primes.append(num)
    return primes

@app.route('/async')
def hello():
    # Divide the work among multiple processes (assuming 4 CPU cores)
    num_processes = 4
    limit = 1000000  # Adjust the limit for more CPU usage
    chunk_size = limit // num_processes
    start_indices = [i * chunk_size + 2 for i in range(num_processes)]
    end_indices = [(i + 1) * chunk_size + 1 for i in range(num_processes)]

    with multiprocessing.Pool(processes=num_processes) as pool:
        results = pool.starmap(calculate_primes, zip(start_indices, end_indices))

    primes = [prime for sublist in results for prime in sublist]
    return "Heavy task completed"

if __name__ == '__main__':
    app.run(host='192.168.2.10', port=80)