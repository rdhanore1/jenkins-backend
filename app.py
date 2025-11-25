# python
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

@app.route('/submit', methods=['POST'])
def submit():
    # Accept both JSON and form-encoded data
    if request.is_json:
        data = request.get_json()
    else:
        data = request.form.to_dict()

    # Basic processing (echo + simple validation)
    name = data.get('name')
    email = data.get('email')
    message = data.get('message')

    errors = []
    if not name:
        errors.append('name is required')
    if not email:
        errors.append('email is required')
    if not message:
        errors.append('message is required')

    if errors:
        return jsonify({'success': False, 'errors': errors}), 400

    # In a real app you'd store or further process the data here
    resp = {
        'success': True,
        'received': {
            'name': name,
            'email': email,
            'message': message
        },
        'note': 'This is a demo response from Flask backend.'
    }

    return jsonify(resp), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
