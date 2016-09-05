# How to run a Python app as an OpenWhisk Docker action

## Execution model

A recent (Sept 2016) update to the *Openwhisk* image `openwhisk/dockerskeleton` has simplified what we have to do to make a Python app into an *OpenWhisk* Docker action by hiding from us any concern over the RESTful api behind the scenes.

All we have to do is to edit the `Dockerfile` and make sure our Python (2.7 right now) is accepting parameters and supplying outputs in the appropriate format.

Note that this will be an Openwhisk *Docker* action. It may be simpler to have Openwhisk run your Python as a *Python action snippet*. However, by doing it in the way described below, you have the freedom to include application assets (data files and Python modules) in your action. 

## How to build the action

First of all follow the IBM Bluemix documentation that describes downloading the `dockerSkeleton` directory with the command `$ wsk sdk install docker`

### The program

File `test.py` (or `whatever_name.py` you will use in your edited `Dockerfile` below.)  

-  Make sure it's executable (`chmod a+x test.py`).
-  Make sure it's got the  shebang on line one.
-  Make sure it runs locally.   
   -  e.g. `./test.py '{"tart":"tarty"}'`    
      produces the JSON dictionary:    
      `{"allparams": {"tart": "tarty", "myparam": "myparam default"}}`

```python
#!/usr/bin/env python

import sys
import json

def main():
  # accept multiple '--param's
  params = json.loads(sys.argv[1])
  # find 'myparam' if supplied on invocation
  myparam = params.get('myparam', 'myparam default')

  # add or update 'myparam' with default or 
  # what we were invoked with as a quoted string
  params['myparam'] = '{}'.format(myparam)

  # output result of this action
  print(json.dumps({ 'allparams' : params}))

if __name__ == "__main__":
  main()
```

### The Dockerfile

Compare the following with the supplied `Dockerfile` supplied by `$ wsk sdk install docker` to take the Python script `test.py` and make it ready to build the docker image.  

Hopefully the comments explain the differences. Any assets (data files or modules) in the current directory will become part of the image as will any Python dependencies listed in `requirements.txt`

```bash
# Dockerfile for Python whisk docker action
FROM openwhisk/dockerskeleton

ENV FLASK_PROXY_PORT 8080

# Install our action's Python dependencies
ADD requirements.txt /action/requirements.txt
RUN cd /action; pip install -r requirements.txt

# Ensure source assets are not drawn from the cache 
# after this date
ENV REFRESHED_AT 2016-09-05T13:59:39Z
# Add all source assets
ADD . /action
# Rename our executable Python action
ADD test.py /action/exec

# Leave CMD as is for Openwhisk
CMD ["/bin/bash", "-c", "cd actionProxy && python -u actionproxy.py"]
```

Note the `ENV REFRESHED_AT ...` which I used to make sure that an updated `test.py` was picked up afresh rather than being drawn from the cache when the image is built.

## Build and push to Docker Hub

Right now  (Sept 2016) OpenWhisk does not invoke Docker action containers run from your BlueMix image registry, it only runs containers instantiated from images that you've pushed to DockerHub. So you'll need a Docker Hub account to proceed (it's free, even for private image repos, and easy to [set up](https://hub.docker.com)). Your login Id is used as your namespace; `<my_namespace>` as in `<my_namespace>/testaction`, for axample.

```bash
$ docker login -u my_namespace -p my_secret
```

## Create and invoke your OpenWhisk action

### Preliminaries

**Note**: You'll need to create a Bluemix *Organisation* in the US South Region in your IBM Bluemix account as, right now  (Sept 2016) *OpenWhisk* is not available in the United Kingdom or Sydney Regions. 

So, you will have done `wsk property set --apihost openwhisk.ng.bluemix.net ...` by now, won't you.

### Down to business

```bash
./buildAndPush.sh my_namespace/skelpy
```

where `mynamespace` is your Docker Hub id / namespace and `skelpy` is just whatever we're naming our image.

Next, we'll need two terminal windows open - `cd`'d to any directory - it won't matter; the `wsk property set` seems to have  a machine-global scope.  

In one :

```bash
$ wsk activation poll
```
This will report on your OpenWhisk actions as they happen asynchronously.


And in the other terminal window: 

```bash
$ wsk action create --docker tryaction my_namespace/skelpy
$ wsk action invoke --blocking --result tryaction \
  --param testString1 'Test String1' \
  --param testString2 'test String2'
```

where `tryaction` is whatever you want to call your *Openwhisk* action.

and you should then get sufficient output to see:


-   In the invoking window:  
    -  how parameters are passed and the JSON string results your action returned.

- In the polling window:

    Something like:

```
[
  "2016-09-05T14:01:57.354441266Z stdout: XXX_THE_END_OF_A_WHISK_ACTIVATION_XXX",
  "2016-09-05T14:01:57.354770942Z stderr: XXX_THE_END_OF_A_WHISK_ACTIVATION_XXX"
]
```

## Disclaimer

I am neither employed by, nor have any business relationships with any of the individuals or organisations I've mentioned on this page. (Although, I spent almost the last quarter of the previous century happily working at IBM's Hursley Lab.) I've written this as a record of my discovery and in the interests of the wider community and also because  I intend to use Bluemix and OpenWhisk in some 
current an future projects.
