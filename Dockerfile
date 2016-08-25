# python-setuptools couldn't be found on xenial and trusty-curl was not found either
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
