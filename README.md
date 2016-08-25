# How to run a Python app as an OpenWhisk Docker action

## Execution model

A Docker action has to start an HTTP server that can handle two requests:

-  **POST /init**: This endpoint is called after the container is started and is not important for Docker actions. It needs to be handled but just needs to respond with a 200.  

-  **POST /run**: This endpoint is called on action invocation. Invocation parameters are provided in the JSON body as a dictionary under the `value` key.

## A Python implementation of the  action server

`test.py` is a proof-of-concept skeleton which you can use to see what gets passed between OpenWhisk and your action code and then can be developed by expanding the function  `wsk_run`.

```python
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
```


#### Notes on the program

1.  The side-effect of `return`ing from either of the functions `wsk_init` or `wsk_run`) is `Flask`  sending a 200 response. [Miguel Grinberg](http://blog.miguelgrinberg.com/post/designing-a-restful-api-with-python-and-flask) has a clear explanation of *Designing a RESTful API with Python and Flask* for more sophistocated responses to checks and validations.

2. `jsonify`  wraps `json.dumps()`. It turns the JSON output into a `Response`  with the `application/json` mimetype. 

3. You need to specify `host='0.0.0.0'` to expose the port to whatever IP Address the  container will have been given by the Docker server at runtime.

4. Also, evidently, the RESTful endpoint for OpenWhisk Docker actions is available through `port=8080`.


## How to build the action

### The Dockerfile

If you've developed your Python Docker app `FROM python:3-onbuild` or what you otherwise might have chosen normally, then it  won't work from that image.  You'll need to build your action from an Ubuntu image otherwise OpenWhisk will not be able to start the action.  
The Bluemix documentation (August 2016)  state that it has to be Ubuntu LTS 14.04 (Trusty Tahr)  but I can confirm that you'll be fine with Ubuntu 16.04.1 LTS (Xenial Xerus). The `buildpack-curl` image and its tagged variants, used in some examples, is not suitable as it removes the apt lists needed to install Python.

```bash
FROM ubuntu:xenial

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget 

# Install Python Setuptools
RUN apt-get install -y python3-setuptools python3-pip
RUN pip3 install --upgrade pip

# Add and install Python modules
ADD requirements.txt /src/requirements.txt
RUN cd /src; pip3 install -r requirements.txt

# Bundle app source (whatever we used to run our python app before containerisation)
ADD . /src

EXPOSE 8080

CMD [ "python3", "/src/test.py" ]
```

## Build and test locally

This is what you do in the directory where your `Dockerfile` is. <my_namespace> is your Docker Hub Id / namespace (See next section if you've not yet got a Docker Hub Id). 

```bash
$ docker build  -t <my_namespace>/testaction .

$ docker  run -d  -p 0.0.0.0:8080:8080 <my_namespace>/testaction

$ curl  -w  "%{http_code}\n"  -H "Content-Type: application/json" \
  http://localhost:8080/init # => 200

$ curl  -w  "%{http_code}\n"  -H "Content-Type: application/json" \
-d '{"value":{"YOUR":"PAYLOAD"}}' http://localhost:8080/run # => 200 and JSON echo'd

```

and, if you're happy:

```bash
$ docker ps # => Container Id
$ docker stop <Container Id>
```

## Push to Docker Hub

Right now  (August 2016) OpenWhisk does not invoke Docker action containers run from your BlueMix image registry, only run from images that you've pushed to DockerHub. So you'll need a Docker Hub account to proceed (it's free, even for private image repos, and easy to [set up](https://hub.docker.com)). Your login Id is used as your namespace; `<my_namespace>` as in `<my_namespace>/testaction`, for axample.

```bash
$ docker login -u <my_namespace> -p <my_secret>
$ docker push  <my_namespace>/testaction
```

## Create and invoke your OpenWhisk action

### Preliminaries

You will need to have [downloaded and installed the OpenWhisk CLI](https://new-console.ng.bluemix.net/openwhisk/cli) - as far as I know, you'll need to have an IBM Bluemix account to do access that page but, again, [sign-up](https://new-console.ng.bluemix.net) is free. 

**Note**: You'll need to create an *Organisation* in the US South Region as you create your IBM Bluemix account as, right now  (August 2016) OpenWhisk is not available in the United Kingdom or Sydney Regions. 

So, you will have done `wsk property set --apihost openwhisk.ng.bluemix.net ...` by now, won't you.

### Down to business

We'll need two terminal windows open - `cd`'d to any directory - it won't matter; the `wsk property set` seems to have  a machine-global scope.  

In one :

```bash
$ wsk activation poll
```
This will report on your OpenWhisk actions as they happen asynchronously.


And in the other terminal window: 

```bash
$ wsk action create --docker tryaction <my_namespace>/testaction
$ wsk action invoke --blocking --result tryaction \
  --param testString1 'Test String1' --param testString2 'test String2'
```

and you should then get sufficient output to see:

1. In the polling window:  
    -  the action's HTTP Server starting up
    -  the responses (complete with 200 response codes) from the action's two endpoint routes - `/init` and `/run` - as they are invoked by OpenWhisk in the form of the action's `stderror` log lines

2. In the invoking window:  
    -  how parameters are passed and the result responses your action returned.

### Developing / updating the action

If and when you re-build the Python Docker action then you'll have to update the OpenWhisk action as OpenWhisk imports an Docker Hub action image afresh at each update rather than keeping a reference to them.

```bash
$ docker build  -t <my_namespace>/testaction .
$ docker push  <my_namespace>/testaction
$ wsk action update --docker tryaction <my_namespace>/testaction
$ wsk action invoke --blocking --result tryaction \
  --param testString1 'Test String1' --param testString2 'test String2'
```

## References

You might  like to check out the following:

-  [Flask](http://flask.pocoo.org/docs/0.11/api/#module-flask.json) reference.
-  Miguel Grinberg [Designing a RESTful API with Python and Flask](http://blog.miguelgrinberg.com/post/designing-a-restful-api-with-python-and-flask)
-  Nick Herman [How to Use OpenWhisk Docker Actions in IBM Bluemix](http://blog.altoros.com/how-to-use-openwhisk-docker-actions-in-ibm-bluemix.html) with a ready-to-go Node.js HTTP server  that runs a sample binary action compiled from C. 
-  [OpenWhisk GitHub source](https://github.com/openwhisk/openwhisk)
-  [IBM developerWorks OpenWhisk home](https://developer.ibm.com/openwhisk/) with a nice diagram of OpenWhisk's High Level Architecture
-  [IBM Bluemix](https://new-console.ng.bluemix.net) home.

## Disclaimer

I am not employed by, or have any business relationships with any of the individuals or organisations I've mentioned on this page. (Although, in the previous century I did work at IBM's Hursley Lab.) I've written it as a record of my discovery and in the interests of the wider community and also because  I intend to use Bluemix and OpenWhisk in some 
current an future projects.
