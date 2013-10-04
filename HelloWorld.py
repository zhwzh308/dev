from bottle import route, run, error, template, static_file
from bottle import BaseRequest
import urllib2
@route('/')
def frontpage():
    return '''
    <title>Search Engine</title>
    <body>
        <img src="http://www.google.com/images/srpr/logo4w.png" alt="Pulpit rock" />
        <p>Please input your keyword:</p>
        <form action="/" method="post">
	Search <input type="text" name="query"><br>
	<button type="submit" >Submit</button>
	<button type="submit" formtarget="_blank">Submit to a new window</button>
	</form>
    </body>
'''
@route('/', method='POST')
def query():
    

@route('/hello')
def hello():
    return 'Hello World!'
@route('/what')
def OK():
    return 'keep calm and carry on'
@route('/hello/<name>')
def greetings(name='Stranger'):
    return template('Hello {{name}}, how are you?', name=name)
@error(404)
def error404(error):
    return 'Error 404: Nothing here, sorry'
@route('/static/<filename>')
def server_static(filename):
    return static_file(filename, root='/nfs/ug/homes-1/z/zhangw31/csc326/bottle-0.11.6/dev/static')
run(host='localhost',port=8080,debug=True)
