# =============================================================================
#  USGS/EROS Inventory Service Example
#  Description: Download Landsat Collection 2 files
#  Usage: python download_sample.py -u username -p password -f filetype
#         optional argument f refers to filetype including 'bundle' or 'band'
# =============================================================================

import json
import requests
import sys
import time
import re
import threading
import os
import numpy as np
import csv
import json
import os
import threading
from datetime import datetime

from landsatxplore.api import API

from NDVI import get_last_date, get_date_range, scene_file_downloaded

FILE_LOCATION = os.path.dirname(os.path.realpath(__file__))

PATH = os.path.join(FILE_LOCATION, "landsat-data")
# maxthreads = 5  # Threads count for downloads
# sema = threading.Semaphore(value=maxthreads)
label = datetime.now().strftime("%Y%m%d_%H%M%S")  # Customized label using date time
threads = []


def get_credentials(path="usgs-pass.json"):
    usgs_username = ""
    usgs_password = ""
    path = "../../usgs-pass.json" # test only
    if os.path.exists(path):
        with open(path, 'r') as file:
            json_data = json.load(file)
            usgs_username = json_data['username']
            usgs_password = json_data['password']
    else:
        usgs_username = os.getenv("LANDSATXPLORE_USERNAME")
        usgs_password = os.getenv("LANDSATXPLORE_PASSWORD")
    if not usgs_username and not usgs_password:
        print("No Credentials found.\n"
              "Export LANDSATXPLORE_USERNAME and LANDSATXPLORE_PASSWORD")
        return None
    return usgs_username, usgs_password


def get_scenes(dataset="landsat_ot_c2_l2", latitude=31.9279, longitude=-109.0929, start_date=None, end_date=None, bbox=None):
    """Return scenes based in the last recorded NDVI

    datase name landsat_ot_c2_l2
    start_date is older
    end_date newer
    bbox (xmin, ymin, xmax, ymax) tuple of the bounding box.
    """
    usgs_username, usgs_password = get_credentials()
    if None in (start_date, end_date):
        start_date, end_date = get_date_range()

    # Initialize a new API instance and get an access key
    api = API(usgs_username, usgs_password)

    # Search for Landsat TM scenes
    scenes = api.search(
        dataset=dataset,
        latitude=latitude,
        longitude=longitude,
        start_date=start_date,
        bbox=bbox,
        end_date=end_date,
        max_results=1000,
        # max_cloud_cover=10
    )
    print()
    print(len(scenes),  ": scenes found.")
    entity_ids = []

    scene_file = "scenes.csv"
    scene_path = os.path.join(FILE_LOCATION, scene_file)

    with open(scene_path, mode='w') as rd:
        headers = list(scenes[0].keys())
        writer = csv.DictWriter(rd, fieldnames=headers)
        writer.writeheader()
        for scene in scenes:
            writer.writerow(scene)
            entity_ids.append(scene['display_id'].strip())

    api.logout()
    print(entity_ids)
    print ()
    print()
    return entity_ids



def update_scene_file(filepath):
    """Create Scenes.txt file

    landsat_ot_c2_l1|displayId
    LC09_L1TP_034038_20220614_20220616_02_T1
    LC08_L1TP_035038_20220613_20220617_02_T1
    """
    start_date, end_date = get_date_range()

    start_date = start_date.replace("-", "")
    end_date = end_date.replace("-", "")

    datas = None
    lens_datas = 0
    with open(filepath, "r") as fr:
        datas = fr.readlines()
        lens_datas = len(datas)

    with open(filepath, "w") as fw:
        for count, lines in enumerate(datas):
            lines = lines.strip()
            if not lines:
                continue
            if count == 0:
                fw.write(lines + "\n")
            else:
                if count == lens_datas - 1:
                    fw.write(lines[:17] + start_date + "_" + end_date + lines[34:])
                else:
                    fw.write(lines[:17] + start_date + "_" + end_date + lines[34:] + "\n")


# Send http request
def sendRequest(url, data, apiKey=None, exitIfNoResponse=True):
    json_data = json.dumps(data)

    if apiKey == None:
        response = requests.post(url, json_data)
    else:
        headers = {'X-Auth-Token': apiKey}
        response = requests.post(url, json_data, headers=headers)

    try:
        httpStatusCode = response.status_code
        if response == None:
            print("No output from service")
            if exitIfNoResponse:
                sys.exit()
            else:
                return False
        output = json.loads(response.text)
        if output['errorCode'] != None:
            print(output['errorCode'], "- ", output['errorMessage'])
            if exitIfNoResponse:
                sys.exit()
            else:
                return False
        if httpStatusCode == 404:
            print("404 Not Found")
            if exitIfNoResponse:
                sys.exit()
            else:
                return False
        elif httpStatusCode == 401:
            print("401 Unauthorized")
            if exitIfNoResponse:
                sys.exit()
            else:
                return False
        elif httpStatusCode == 400:
            print("Error Code", httpStatusCode)
            if exitIfNoResponse:
                sys.exit()
            else:
                return False
    except Exception as e:
        response.close()
        print(e)
        if exitIfNoResponse:
            sys.exit()
        else:
            return False
    response.close()

    return output['data']


def downloadFile(url, dir_path=PATH, scence=""):
    try:
        response = requests.get(url, stream=True)
        disposition = response.headers['content-disposition']
        filename = re.findall("filename=(.+)", disposition)[0].strip("\"")
        print(f"Downloading {filename} ...\n")
        path = os.path.join(dir_path, scence, filename)
        open(path, 'wb').write(response.content)
        print(f"Downloaded {filename}\n")
    except Exception as e:
        print(f"Failed to download from {url}. Will try to re-download.")
        print("Exiting downloadFile")
        exit()
        # return False
    return True


if __name__ == '__main__':

    username, password = get_credentials()
    filetype = 'band'
    entityIds = []
    datasetName = "landsat_ot_c2_l2"
    idField = "displayId"
    serviceUrl = "https://m2m.cr.usgs.gov/api/api/json/stable/"

    if not os.path.exists(PATH):
        os.mkdir(PATH)

    # get Portal scenes
    entityIds = get_scenes()
    un_downloaded, zero_bites = scene_file_downloaded(scenes=entityIds, data_path=PATH, filetype=filetype)
    if not un_downloaded:
        print("All files downloaded")
    else:
        print("Un downloaded scenes :", un_downloaded)
    if zero_bites:
        print()
        print("Empty scene files downloaded")
        print(zero_bites)
        
