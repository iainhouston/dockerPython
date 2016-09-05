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