#!/usr/bin/python3

"""
Download the new weather data from the logger and post on the web

Due to issues with how the data logger dynamically generates its data tables the
data cannot be downloaded directly by Travis CI. This script runs on a separate
web server once a day to obtain the most recent weather data and then posts a
static version to the web for the continuous integration infrastructure to work
with.

Currently the script is deployed on a Digital Ocean. To be given access to the
server contact Ethan. The cron job runs at 02:26 UTC and takes several minutes to
complete.

The resulting data is available at:

Weather: http://157.230.136.69/weather-data.html
Storms: http://157.230.136.69/storms-data.html

The script is downloaded from this repo by the server once a day and then
executed to update the data. Therefore changes to this script in this repo will
be integrated at the next daily run.
"""

import requests
import os
import shutil

if os.path.exists('weather-data.html'):
    os.remove('weather-data.html')
if os.path.exists('storms-data.html'):
    os.remove('storms-data.html')

weather_url = 'http://166.153.133.121/?command=TableDisplay&table=MET&records=200'
storms_url = 'http://166.153.133.121/?command=TableDisplay&table=Storms&records=1650'

r_weather = requests.get(weather_url, allow_redirects=True)
open('weather-data.html', 'wb').write(r_weather.content)
shutil.copyfile('weather-data.html', '/var/www/html/weather-data.html')

r_storms = requests.get(storms_url, allow_redirects=True)
open('storms-data.html', 'wb').write(r_storms.content)
shutil.copyfile('storms-data.html', '/var/www/html/storms-data.html')
