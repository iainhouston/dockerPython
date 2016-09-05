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