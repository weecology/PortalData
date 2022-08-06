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

path = "landsat-data"
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
        usgs_username = os.getenv("LANDSATXPLORE_USERNAME")
        usgs_password = os.getenv("LANDSATXPLORE_PASSWORD")
    if not usgs_username and not usgs_password:
        print("No Credentials found.\n"
              "Export LANDSATXPLORE_USERNAME and LANDSATXPLORE_PASSWORD")
        return None
    return usgs_username, usgs_password


def get_last_date(path="/NDVI/ndvi.csv"):
    """Get last recorded date from NDVI/ndvi.csv"""
    rec = None
    with open(path, "r") as records:
        rec = records.readlines()
    return rec[-1].split(",")[0]


def get_date_range():
    """Returns start and end date YY-MM-DD Formatted"""
    start_date = get_last_date()
    # start_date = "2022-07-30"
    now = datetime.now()
    end_date = now.strftime("%Y-%m-%d")
    return start_date, end_date


def get_scenes(dataset="landsat_ot_c2_l1", latitude=31.9279, longitude=-109.0929, start_date=None, end_date=None, bbox=None):
    """Return scenes based in the last recorded NDVI

    datase name landsat_ot_c2_l1
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
        # max_cloud_cover=10
    )
    print(len(scenes),  ": scenes found.")
    entity_ids = []

    with open("scenes.csv", mode='w') as rd:
        headers = list(scenes[0].keys())
        writer = csv.DictWriter(rd, fieldnames=headers)
        writer.writeheader()
        for scene in scenes:
            writer.writerow(scene)
            entity_ids.append(scene['display_id'].strip())

    api.logout()
    return entity_ids


def update_scene_file(filepath):
    """Create Scenes.txt file

    landsat_ot_c2_l1|displayId
    LC09_L1TP_034038_20220614_20220616_02_T1
    LC08_L1TP_035038_20220613_20220617_02_T1
    """
    start_date, end_date = get_dates()

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


def downloadFile(url):
    sema.acquire()
    try:
        response = requests.get(url, stream=True)
        disposition = response.headers['content-disposition']
        filename = re.findall("filename=(.+)", disposition)[0].strip("\"")
        print(f"Downloading {filename} ...\n")
        if path != "" and path[-1] != "/":
            filename = "/" + filename
        open(path + filename, 'wb').write(response.content)
        print(f"Downloaded {filename}\n")
        sema.release()
    except Exception as e:
        print(f"Failed to download from {url}. Will try to re-download.")
        sema.release()
        runDownload(threads, url)


def runDownload(threads, url):
    thread = threading.Thread(target=downloadFile, args=(url,))
    threads.append(thread)
    thread.start()


if __name__ == '__main__':

    username, password = get_credentials()
    filetype = None
    entityIds = []
    datasetName = "landsat_ot_c2_l1"
    idField = "displayId"
    serviceUrl = "https://m2m.cr.usgs.gov/api/api/json/stable/"

    if not os.path.exists(path):
        os.mkdir(path)

    # get Portal scenes
    entityIds = get_scenes()

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
                        downloads.append(
                            {"entityId": secondaryDownload["entityId"], "productId": secondaryDownload["id"]})
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
        if results != False:
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
            time.sleep(30)
            results = sendRequest(serviceUrl + "download-retrieve", payload, apiKey, False)
            if results != False:
                for result in results['available']:
                    if result['downloadId'] in preparingDownloadIds:
                        preparingDownloadIds.remove(result['downloadId'])
                        print(f"Get download url: {result['url']}\n")
                        runDownload(threads, result['url'])

    print("\nGot download urls for all downloads\n")
    # Logout
    endpoint = "logout"
    if sendRequest(serviceUrl + endpoint, None, apiKey) == None:
        print("Logged Out\n")
    else:
        print("Logout Failed\n")

    print("Downloading files... Please do not close the program\n")

    for thread in threads:
        thread.join()

    print("Complete Downloading")

    executionTime = round((time.time() - startTime), 2)
    print(f'Total time: {executionTime} seconds')

