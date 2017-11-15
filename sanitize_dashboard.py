#!/usr/bin/python3

import fileinput
import json

dashboard = json.loads(''.join(fileinput.input()))
dashboard.pop('__inputs')
dashboard.pop('__requires')
print(json.dumps(dashboard).replace('${DS_PROMETHEUS}', 'prometheus1'))
