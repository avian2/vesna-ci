import os

# URL where logs will be accessible so that they can be properly linked
# from commit status messages.
#
# "http://foo/bar" means that logs should be accessible at
# "http://foo/bar/logs/build.*.html".
#
# WARNING: Make sure that "vesna-ci" directory itself isn't available over
# the web as it contains files with sensitive information!
BASE_URL = "http://log-a-tec.eu/vesna-ci"

BASE_DIR = os.path.dirname(__file__)

# Github repository that will be checked for open pull requests.
REPO = "sensorlab/vesna-drivers"
