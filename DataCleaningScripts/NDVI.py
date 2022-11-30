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
import pandas as pd
import csv
import json
import os
import threading
from datetime import datetime
from datetime import timedelta, date

from landsatxplore.api import API

NDVI_DIR = os.path.normpath(os.path.abspath(__file__ + "/../../NDVI"))
PATH = os.path.join(NDVI_DIR, "landsat-data")
NDVI_SCENES = os.path.join(NDVI_DIR, "scenes.csv")
NDVI_CSV = os.path.join(NDVI_DIR, "ndvi.csv")
UNDONE_SCENES = os.path.join(NDVI_DIR, "undone-scenes.csv")

maxthreads = 5  # Threads count for downloads
sema = threading.Semaphore(value=maxthreads)
label = datetime.now().strftime("%Y%m%d_%H%M%S")  # Customized label using date time
threads = []


def get_credentials(path="usgs-pass.json"):
    usgs_username = ""
    usgs_password = ""

    if os.path.exists(path):
        with open(path, 'r') as file:
            json_data = json.load(file)
            usgs_username = json_data['username']
            usgs_password = json_data['password']
    else:
        usgs_username = "weecology"
        usgs_password = os.environ["USGS_PASSWORD"]
    if not usgs_username and not usgs_password:
        print("No Credentials found.\n"
              "Export LANDSATXPLORE_USERNAME and LANDSATXPLORE_PASSWORD")
        return None
    return usgs_username, usgs_password


def get_last_date(ndvi_file=NDVI_CSV):
    """Get last recorded date from NDVI/ndvi.csv"""
    ndvi_df = pd.read_csv(ndvi_file)
    return ndvi_df['date'].iat[-1]


def get_date_range():
    """Returns start and end date YY-MM-DD Formatted"""
    start_date = get_last_date()
    start_date = datetime.strptime(start_date, "%Y-%m-%d") + timedelta(days=1)
    start_date = start_date.strftime("%Y-%m-%d")
    now = datetime.now()
    end_date = now.strftime("%Y-%m-%d")
    return start_date, end_date


def get_scenes(dataset="landsat_ot_c2_l2", latitude=31.9279, longitude=-109.0929, start_date=None, end_date=None, bbox=None, scene_file=None):
    """Return scenes based in the last recorded NDVI

    datase name landsat_ot_c2_l2
    start_date is older
    end_date newer
    bbox (xmin, ymin, xmax, ymax) tuple of the bounding box.
    Scene_file store the metadata.
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
    print(len(scenes),  ": scenes found.")
    entity_ids = []
    if not scene_file:
        scene_file = NDVI_SCENES
    scene_path = os.path.normpath(scene_file)

    with open(scene_path, mode='w') as rd:
        headers = list(scenes[0].keys())
        writer = csv.DictWriter(rd, fieldnames=headers)
        writer.writeheader()
        for scene in scenes:
            writer.writerow(scene)
            entity_ids.append(scene['display_id'].strip())

    api.logout()
    print(entity_ids)
    return entity_ids


def scene_file_downloaded(scenes, data_path, filetype, dataset="landsat_ot_c2_l2"):
    """Check if the scenes have all the corresponding files downloaded

    Scense id
    Data_path
    Filetype provided, band, zip
    Dataset name, landsat_etm_c2_l2, landsat_ot_c2_l1, landsat_ot_c2_l2
    """
    un_finised_scenes = []
    zero_bites = []

    exts = {
    "landsat_ot_c2_l1": [".jpg", ".tar", "_ANG.txt", "_B1.TIF", "_B10.TIF", "_B11.TIF", "_B2.TIF", "_B3.TIF", "_B4.TIF", "_B5.TIF", "_B6.TIF", "_B7.TIF", "_B8.TIF", "_B9.TIF", "_MTL.txt", "_MTL.xml", "_QA_PIXEL.TIF", "_QA_RADSAT.TIF", "_QB.jpg", "_qb.tif", "_refl.tif", "_SAA.TIF", "_SZA.TIF", "_TIR.jpg", "_tir.tif", "_VAA.TIF", "_VZA.TIF"],
    "landsat_ot_c2_l2": ["_ANG.txt", "_MTL.txt", "_MTL.xml", "_QA_PIXEL.TIF", "_QA_RADSAT.TIF", "_SR_B1.TIF", "_SR_B2.TIF", "_SR_B3.TIF", "_SR_B4.TIF", "_SR_B5.TIF", "_SR_B6.TIF", "_SR_B7.TIF", "_SR_QA_AEROSOL.TIF", "_ST_ATRAN.TIF", "_ST_B10.TIF", "_ST_CDIST.TIF", "_ST_DRAD.TIF", "_ST_EMIS.TIF", "_ST_EMSD.TIF", "_ST_QA.TIF", "_ST_TRAD.TIF", "_ST_URAD.TIF"]
    }

    all_extensions = exts[dataset.lower()]
    if filetype == 'band':
        # ext_remove = [".jpg", ".tar", "_QB.jpg", "_TIR.jpg", "_qb.tif", "_refl.tif", "_tir.tif"]
        # all_extensions = [ext for ext in all_extensions if ext not in ext_remove]
        all_extensions = all_extensions
    else:
        all_extensions = all_extensions
    for scene in scenes:
        for ext in all_extensions:
            file_path = os.path.join(data_path, scene + ext)
            if os.path.isfile(file_path) and  os.stat(file_path).st_size == 0:
                zero_bites.append(scene, file_path)
            if not os.path.isfile(file_path):
                un_finised_scenes.append(scene + ext)
    return un_finised_scenes, zero_bites


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
    sema.acquire()
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
        sema.release()
        runDownload(threads, url)
    sema.release()


def runDownload(threads, url, dir_path=PATH, scence=""):
    thread = threading.Thread(target=downloadFile, args=(url, dir_path, scence))
    threads.append(thread)
    thread.start()


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

    # Add previously failed or un downloaded scenes
    old_undownloaded = pd.read_csv(UNDONE_SCENES)
    failed_entities = list(old_undownloaded['display_id'])
    entityIds = list(set(entityIds + failed_entities))

    print("\nRunning Scripts...\n")
    startTime = time.time()

    # Login
    payload = {'username': username, 'password': password}
    apiKey = sendRequest(serviceUrl + "login", payload)

    # Add scenes to a list
    listId = f"temp_{datasetName}_list"  # customized list id
    payload = {
        "listId": listId,
        'idField': idField,
        "entityIds": entityIds,
        "datasetName": datasetName
    }

    print("Adding scenes to list...\n")
    count = sendRequest(serviceUrl + "scene-list-add", payload, apiKey)
    print("Added", count, "scenes\n")

    # Get download options
    payload = {
        "listId": listId,
        "datasetName": datasetName
    }

    print("Getting product download options...\n")
    products = sendRequest(serviceUrl + "download-options", payload, apiKey)
    print("Got product download options\n")

    # Select products
    downloads = []
    if filetype == 'bundle':
        # select bundle files
        for product in products:
            if product["bulkAvailable"]:
                downloads.append({"entityId": product["entityId"], "productId": product["id"]})
    elif filetype == 'band':
        # select band files
        for product in products:
            if product["secondaryDownloads"] is not None and len(product["secondaryDownloads"]) > 0:
                for secondaryDownload in product["secondaryDownloads"]:
                    if secondaryDownload["bulkAvailable"]:
                        payload = {'username': username, 'password': password}
                        apiKey = sendRequest(serviceUrl + "login", payload)
                        downloads.append({"entityId": secondaryDownload["entityId"], "productId": secondaryDownload["id"]})
    else:
        # select all available files
        for product in products:
            if product["bulkAvailable"]:
                downloads.append({"entityId": product["entityId"], "productId": product["id"]})
                if product["secondaryDownloads"] is not None and len(product["secondaryDownloads"]) > 0:
                    for secondaryDownload in product["secondaryDownloads"]:
                        if secondaryDownload["bulkAvailable"]:
                            downloads.append(
                                {"entityId": secondaryDownload["entityId"], "productId": secondaryDownload["id"]})

    # Remove the list
    payload = {
        "listId": listId
    }
    sendRequest(serviceUrl + "scene-list-remove", payload, apiKey)

    # Send download-request
    payLoad = {
        "downloads": downloads,
        "label": label,
        'returnAvailable': True
    }

    print(f"Sending download request ...\n")
    results = sendRequest(serviceUrl + "download-request", payLoad, apiKey)
    print(f"Done sending download request\n")

    for result in results['availableDownloads']:
        print(f"Get download url: {result['url']}\n")
        runDownload(threads, result['url'])

    preparingDownloadCount = len(results['preparingDownloads'])
    preparingDownloadIds = []
    if preparingDownloadCount > 0:
        for result in results['preparingDownloads']:
            preparingDownloadIds.append(result['downloadId'])

        payload = {"label": label}
        # Retrieve download urls
        print("Retrieving download urls...\n")
        results = sendRequest(serviceUrl + "download-retrieve", payload, apiKey, False)
        if results:
            for result in results['available']:
                if result['downloadId'] in preparingDownloadIds:
                    preparingDownloadIds.remove(result['downloadId'])
                    print(f"Get download url: {result['url']}\n")
                    runDownload(threads, result['url'])

            for result in results['requested']:
                if result['downloadId'] in preparingDownloadIds:
                    preparingDownloadIds.remove(result['downloadId'])
                    print(f"Get download url: {result['url']}\n")
                    runDownload(threads, result['url'])

        # Don't get all download urls, retrieve again after 30 seconds
        while len(preparingDownloadIds) > 0:
            print(f"{len(preparingDownloadIds)} downloads are not available yet. Waiting for 30s to retrieve again\n")
            time.sleep(100)
            payload = {'username': username, 'password': password}
            apiKey = sendRequest(serviceUrl + "login", payload)
            results = sendRequest(serviceUrl + "download-retrieve", payload, apiKey, False)
            if results:
                for result in results['available']:
                    if result['downloadId'] in preparingDownloadIds:
                        preparingDownloadIds.remove(result['downloadId'])
                        print(f"Get download url: {result['url']}\n")
                        runDownload(threads, result['url'])

    print("Downloading files... Please do not close the program\n")

    for thread in threads:
        thread.join()

    print("Complete Downloading")
    print("\nGot download urls for all downloads\n")
    # Logout
    endpoint = "logout"
    if sendRequest(serviceUrl + endpoint, None, apiKey) == None:
        print("Logged Out\n")
    else:
        print("Logout Failed\n")
    executionTime = round((time.time() - startTime), 2)
    print(f'Total time: {executionTime} seconds')

    un_downloaded, zero_bites = scene_file_downloaded(scenes=entityIds, data_path=PATH, filetype=filetype)
    if not un_downloaded:
        print("All files downloaded")
    else:
        print("Un downloaded scenes :", un_downloaded)
    if zero_bites:
        print()
        print("Empty scene files downloaded")
        print(zero_bites)

    # Save to un downloaded scenes.
    unique_ids = list(set(un_downloaded + zero_bites))

    # dictionary of un downloaded entity ids or scenes
    undone_ids = {'display_id': unique_ids}

    df = pd.DataFrame(undone_ids)
    df.to_csv(UNDONE_SCENES, index=False)

    # remove failed downloads from scenes.csv
    # new_scenefile = pd.read_csv(NDVI_SCENES)
    # a = new_scenefile[ ~new_scenefile[ "display_id" ].isin(list(unique_ids["display_id"]))]
    # a.to_csv(NDVI_SCENES, index=False)

