from flask import Flask, jsonify
import subprocess


app = Flask(__name__)



@app.route('/state', methods = ['GET'])
def get_state():
    # Divide the work among multiple processes (assuming 4 CPU cores)
    try:
        cmd = 'echo "register_read MyIngress.state_var1 0" | simple_switch_CLI'
        output = subprocess.check_output(cmd, shell=True, universal_newlines=True)
        output = output.strip()
        output = output.split("\n")
        ### parse the output
        output= output[3]
        print(output.strip())
        state_value = output.split("=")[1].strip()
        return jsonify({'state':int(state_value)})
    except Exception as e:
        print(e)
        data = {'status':'error'}
        return jsonify(data),500





@app.route('/upscale', methods = ['POST'])
def upscale():
    cmd = 'echo "register_write MyIngress.state_var1 0 1" | simple_switch_CLI'
    return_code = subprocess.call(cmd, shell=True)
    if return_code==0:
        data = {'status':'success'}
        return jsonify(data)
    else:
        data = {'status':'error'}
        return jsonify(data),500


@app.route('/downscale', methods = ['POST'])
def downscale():
    cmd = 'echo "register_write MyIngress.state_var1 0 0" | simple_switch_CLI'
    return_code = subprocess.call(cmd, shell=True)
    if return_code==0:
        data = {'status':'success'}
        return jsonify(data)
    else:
        data = {'status':'error'}
        return jsonify(data),500

if __name__ == '__main__':
    app.run(host='192.168.4.1', port=8080)
                                                                                                                                        