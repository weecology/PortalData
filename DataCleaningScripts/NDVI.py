# ==============================================================================================
#  USGS/EROS Inventory
# https://code.usgs.gov/eros-user-services/machine_to_machine/m2m_landsat_bands_bundle_download
# M2M_Bands_Bundles_BandGroups_Download_v5.ipynb
# ==============================================================================================

import json
import requests
from getpass import getpass
import sys
import time
import re
import threading
import os
import pandas as pd

from datetime import datetime
from datetime import timedelta, date

import warnings
warnings.filterwarnings("ignore")


serviceUrl = "https://m2m.cr.usgs.gov/api/api/json/stable/"
bandNames = {"_SR_B4.TIF", "_SR_B5.TIF", "_QA_PIXEL.TIF"}
maxthreads = 5 # Threads count for downloads
max_download_attempts = 3
sema = threading.Semaphore(value=maxthreads)
label = datetime.now().strftime("%Y%m%d_%H%M%S") # Customized label using date time
threads = []
download_attempts = {}

NDVI_DIR = os.path.normpath(os.path.abspath(__file__ + "/../../NDVI"))
PATH = os.path.join(NDVI_DIR, "landsat-data")
NDVI_SCENES = os.path.join(NDVI_DIR, "scenes.csv")
NDVI_CSV = os.path.join(NDVI_DIR, "ndvi.csv")
UNDONE_SCENES = os.path.join(NDVI_DIR, "undone-scenes.csv")


# Send HTTP request
def sendRequest(url, data, apiKey=None, exitIfNoResponse=True):
    headers = {'Content-Type': 'application/json'}
    if apiKey is not None:
        headers['X-Auth-Token'] = apiKey

    response = requests.post(url, json=data, headers=headers, timeout=300)

    try:
        if response.status_code != 200:
            print(f"HTTP {response.status_code} from {url}")
            print(response.text[:500])
            if exitIfNoResponse:
                sys.exit(1)
            return False
        if not response.text:
            print(f"Empty response from {url}")
            if exitIfNoResponse:
                sys.exit(1)
            return False
        output = response.json()
        if output['errorCode'] is not None:
            print(output['errorCode'], "- ", output['errorMessage'])
            if exitIfNoResponse:
                sys.exit(1)
            return False
    except Exception as e:
        response.close()
        print(e)
        if exitIfNoResponse:
            sys.exit(1)
        return False
    response.close()
    return output['data']


def downloadFile(url, out_dir):
    sema.acquire()
    try:
        response = requests.get(url, stream=True, timeout=300)
        disposition = response.headers['content-disposition']
        filename = re.findall("filename=(.+)", disposition)[0].strip("\"")
        filepath = os.path.join(out_dir, filename)

        if os.path.isfile(filepath) and os.stat(filepath).st_size > 0:
            print(f"    Skipping existing file: {filename}")
            sema.release()
            return

        print(f"    Downloading: {filename} -- {url}...")
        open(filepath, 'wb').write(response.content)
        sema.release()
    except Exception as e:
        print(f"\nFailed to download from {url}. {e}")
        sema.release()
        attempts = download_attempts.get(url, 0)
        if attempts < max_download_attempts:
            print(f"Will try to re-download (attempt {attempts + 1}/{max_download_attempts}).")
            runDownload(threads, url, out_dir)
        else:
            print(f"Gave up after {max_download_attempts} attempts: {url}")


def previous_undownloaded(entityIds):
    # Re-queue previously failed scenes (entityId column when present)
    if os.path.exists(UNDONE_SCENES):
        try:
            old_undownloaded = pd.read_csv(UNDONE_SCENES)
            if 'entityId' in old_undownloaded.columns:
                failed_entities = [
                    eid for eid in old_undownloaded['entityId'].dropna().tolist() if str(eid).strip()
                ]
            else:
                # Legacy displayId-only files cannot be mixed with entityId idField
                failed_entities = []
            entityIds = list(dict.fromkeys(list(entityIds) + failed_entities))
        except Exception:
            return list(dict.fromkeys(entityIds))
    return list(dict.fromkeys(entityIds))


# Function to extract the first occurrence of a field from metadata
def extract_first_field(metadata, field_name):
    """
    Extract the first occurrence of a specific field from metadata.

    Parameters:
    - metadata (list): List of metadata dictionaries
    - field_name (str): Name of the field to extract

    Returns:
    - The value of the first occurrence of the field, or None if not found
    """
    if not metadata or not isinstance(metadata, list):
        return None

    value = None
    for item in metadata:
        if isinstance(item, dict) and item.get('fieldName') == field_name:
            value = item.get('value')

            # Standardize date format for "Date Acquired"
            if field_name == "Date Acquired" and value:
                try:
                    # Try to parse and reformat the date consistently
                    parsed_date = datetime.strptime(value, "%Y-%m-%d")
                    value = parsed_date.strftime("%Y-%m-%d")
                except:
                    pass
            return value
    return None


def runDownload(threads, url, out_dir):
    download_attempts[url] = download_attempts.get(url, 0) + 1
    thread = threading.Thread(target=downloadFile, args=(url, out_dir,))
    threads.append(thread)
    thread.start()


def get_last_date(ndvi_file=NDVI_CSV):
    """Get last successfully processed scene date from NDVI/ndvi.csv.

    Uses the last row with pixel_count > 0 (downloaded & processed, including
    fully cloudy scenes). Rows with pixel_count == 0 are download/processing
    failures and must not advance the search window.
    """
    print(ndvi_file)
    ndvi_df = pd.read_csv(ndvi_file)
    processed = ndvi_df[ndvi_df['pixel_count'].fillna(0) > 0]
    if len(processed) > 0:
        return processed['date'].iat[-1]
    # Legacy rows (e.g. GIMMS) may lack pixel_count but still have ndvi
    with_ndvi = ndvi_df[ndvi_df['ndvi'].notna()]
    if len(with_ndvi) > 0:
        return with_ndvi['date'].iat[-1]
    return ndvi_df['date'].iat[-1]


def get_date_range():
    """Returns start and end date YY-MM-DD Formatted"""
    debug_mode = os.environ.get('DEBUGMODE', '').lower() in ('true', '1', 't')

    # Get the start date as a datetime object
    start_date_str = get_last_date()
    start_date_dt = datetime.strptime(start_date_str, "%Y-%m-%d") + timedelta(days=1)

    # Get the current date
    now = datetime.now()

    if debug_mode:
        # Calculate end date (either start + 16 days or today, whichever is earlier)
        end_date_dt = min(start_date_dt + timedelta(days=16), now)
        print(f"DEBUG MODE: {start_date_dt.strftime('%Y-%m-%d')} to {end_date_dt.strftime('%Y-%m-%d')}")
    else:
        # In normal mode, end date is today
        end_date_dt = now

    # Format both dates as strings before returning
    return start_date_dt.strftime("%Y-%m-%d"), end_date_dt.strftime("%Y-%m-%d")


def scene_file_downloaded(scenes_pd, data_path, dataset="landsat_ot_c2_l2"):
    """Check if the scenes have all the corresponding files downloaded

    Scense id
    Data_path
    Filetype provided, band, zip
    Dataset name, landsat_etm_c2_l2, landsat_ot_c2_l1, landsat_ot_c2_l2
    """
    un_finised_scenes = []
    zero_bites = []
    unfinished_entity_ids = []

    exts = {
    "landsat_ot_c2_l2": ["_SR_B4.TIF", "_SR_B5.TIF", "_QA_PIXEL.TIF"]
    }

    all_extensions = exts[dataset.lower()]
    for _, row in scenes_pd.iterrows():
        scene = str(row['displayId']).strip()
        if not scene:
            continue
        missing = False
        for ext in all_extensions:
            file_path = os.path.join(data_path, scene + ext)
            if os.path.isfile(file_path) and os.stat(file_path).st_size == 0:
                zero_bites.append(scene)
                missing = True
                print(f"Zero byte file: by scene {scene}, {file_path}")
            if not os.path.isfile(file_path):
                missing = True
                print(f"Unfinished scene: {scene}, {file_path}")
        if missing:
            un_finised_scenes.append(scene)
            if 'entityId' in scenes_pd.columns and pd.notna(row.get('entityId')):
                unfinished_entity_ids.append(row['entityId'])
    return un_finised_scenes, zero_bites, unfinished_entity_ids


def get_credentials(path="~/.usgs-pass.json"):
    """Retrieve USGS credentials from a JSON file or environment variables."""
    path = os.path.expanduser(path)
    usgs_username = "weecology"
    api_token = None

    if os.path.exists(path) and os.path.isfile(path):
        try:
            with open(path, 'r') as file:
                json_data = json.load(file)
                usgs_username = json_data.get('USGS_USERNAME', usgs_username)
                api_token = json_data.get('USGS_API_TOKEN')
        except (json.JSONDecodeError, IOError) as e:
            print(f"Error reading credentials file: {e}")
    else:
        api_token = os.environ.get("USGS_API_TOKEN")

    if not api_token:
        print("API token is required. Set USGS_API_TOKEN in environment or credentials file")
        return None
    return usgs_username, api_token


def prompt_ERS_login(serviceURL):
    print("Logging in...\n")
    username, token = get_credentials()
    response = requests.post(f"{serviceUrl}login-token", json={'username':username, 'token': token})

    if response.status_code == 200:
        apiKey = response.json()['data']
        print('\nLogin Successful, API Key Received!')
        return apiKey
    else:
        print("\nLogin was unsuccessful, please try again or create an account at: https://ers.cr.usgs.gov/register.")


def get_download_options(listId, datasetName, bandGroup):
    """
    Retrieve download options for a specified dataset.

    Parameters:
    - listId (str): The identifier for the list of items to download.
    - datasetName (str): The name of the dataset from which to obtain download options.
    - bandGroup (bool): A flag indicating whether to include secondary file groups.
                        If True, secondary file groups will be included in the payload.

    Returns:
    - dict: A dictionary containing the available products for download.
    """

    # Prepare the payload for the download options request
    download_opt_payload = {
        "listId": listId,
        "datasetName": datasetName
    }

    # If bandGroup is specified, include the secondary file groups in the payload
    if bandGroup:
        download_opt_payload['includeSecondaryFileGroups'] = True

    # Print the payload for debugging purposes
    print(f"download_opt_payload: {download_opt_payload}")

    # Send request to the download options endpoint and retrieve list of available products
    products = sendRequest(serviceUrl + "download-options", download_opt_payload, apiKey)
    return products


def run_download_request(download_req_payload):
    """
    Sends a download request to the specified service and handles the response.

    Parameters:
    - download_req_payload (dict): The payload containing parameters needed to execute the download request. example:
                                    {
                                    "downloads": [{'entityId': 'L2SR_LC08_L2SP_068018_20200310_20200822_02_T1_SR_B2_TIF',
                                                       'productId': '5f85f041a2ea6695'},
                                                      {'entityId': 'L2ST_LC08_L2SP_068018_20200310_20200822_02_T1_ST_B10_TIF',
                                                       'productId': '5f85f041a2ea6695'}],
                                    "label": '20250108_174449'
                                    }
                                    where downloads is a list of entityIds and productIds for each Item being downloaded and a "label" is
                                    a user define string

    Returns:
    - dict: A dictionary of available URLs

    Exits the program if no records are returned from the download request.
    """

    print(f"Sending a download request...")
    # Send the download request using the provided payload and store the results
    download_request_results = sendRequest(serviceUrl + "download-request", download_req_payload, apiKey)

    # Check if any new records or duplicate products were returned
    if len(download_request_results['newRecords']) == 0 and len(download_request_results['duplicateProducts']) == 0:
        print('No records returned, please update your scenes or scene-search filter')
        sys.exit()
    else:
        return download_request_results


def run_download_retrieve(download_request_results, out_dir):

    # Attempt the download URLs
    for result in download_request_results['availableDownloads']:
        # print(f"Get download url: {result['url']}\n" )
        runDownload(threads, result['url'], out_dir)

    # Get items labeled as being prepared for Download
    preparingDownloadCount = len(download_request_results['preparingDownloads'])
    preparingDownloadIds = []
    if preparingDownloadCount > 0:
        for result in download_request_results['preparingDownloads']:
            preparingDownloadIds.append(result['downloadId'])

        download_ret_payload = {"label" : label}
        # Retrieve download URLs
        print("Retrieving download urls...\n")
        download_retrieve_results = sendRequest(serviceUrl + "download-retrieve", download_ret_payload, apiKey, False)
        if download_retrieve_results != False:
            print(f"    Retrieved: \n" )
            for result in download_retrieve_results['available']:
                if result['downloadId'] in preparingDownloadIds:
                    preparingDownloadIds.remove(result['downloadId'])
                    runDownload(threads, result['url'], out_dir)
                    print(f"       {result['url']}\n" )

            for result in download_retrieve_results['requested']:
                if result['downloadId'] in preparingDownloadIds:
                    preparingDownloadIds.remove(result['downloadId'])
                    runDownload(threads, result['url'], out_dir)
                    print(f"       {result['url']}\n" )

        # Didn't get all download URLs, retrieve again after 30 seconds
        while len(preparingDownloadIds) > 0:
            print(f"{len(preparingDownloadIds)} downloads are not available yet. Waiting for 30s to retrieve again\n")
            time.sleep(30)
            download_retrieve_results = sendRequest(serviceUrl + "download-retrieve", download_ret_payload, apiKey, False)
            if download_retrieve_results != False:
                for result in download_retrieve_results['available']:
                    if result['downloadId'] in preparingDownloadIds:
                        preparingDownloadIds.remove(result['downloadId'])
                        print(f"    Get download url: {result['url']}\n" )
                        runDownload(threads, result['url'], out_dir)

    print(f"\nDownloading {len(download_request_results['availableDownloads'])} files... Please do not close the program\n")
    for thread in threads:
        thread.join()


if __name__ == '__main__':

    maxthreads = 5 # Threads count for downloads
    sema = threading.Semaphore(value=maxthreads)
    label = datetime.now().strftime("%Y%m%d_%H%M%S") # Customized label using date time
    threads = []
    download_attempts.clear()

    out_dir = data_dir = PATH
    if not os.path.exists(data_dir):
        os.makedirs(data_dir)
    apiKey = prompt_ERS_login(serviceUrl)
    starts, ends = get_date_range()

    datasetName = 'landsat_ot_c2_l2'
    spatialFilter =  {'filterType' : 'mbr',
                        'lowerLeft' : {'latitude' : 31.8279,\
                                       'longitude' : -109.1929},
                       'upperRight' : { 'latitude' : 32.027,\
                                       'longitude' : -108.9929}}

    temporalFilter = {'start' : starts, 'end' : ends}
    cloudCoverFilter = {'min' : 0, 'max' : 100}
    # metadataType must be set; omitting it can return Summary+Full+FGDC rows per scene
    search_payload = {
        'datasetName' : datasetName,
        'metadataType': 'full',
        'sceneFilter' : {
            'spatialFilter' : spatialFilter,
            'acquisitionFilter' : temporalFilter,
            'cloudCoverFilter' : cloudCoverFilter
        }
    }
    scenes = sendRequest(serviceUrl + "scene-search", search_payload, apiKey)
    print(len(scenes['results']))
    if len(scenes['results']) == 0:
        pd.DataFrame(columns=['displayId', 'entityId']).to_csv(UNDONE_SCENES, index=False)
        sys.exit(0)

    scence_pd = pd.json_normalize(scenes['results'])
    # Drop duplicate scenes if the API still returns repeated entityIds
    if 'entityId' in scence_pd.columns:
        before = len(scence_pd)
        scence_pd = scence_pd.drop_duplicates(subset=['entityId'], keep='first')
        if len(scence_pd) < before:
            print(f"Removed {before - len(scence_pd)} duplicate scene-search rows")

    # Check if 'metadata' column exists before trying to extract from it
    if 'metadata' in scence_pd.columns:
        # Extract 'Date Acquired' and 'Satellite' from metadata
        scence_pd['date_acquired'] = scence_pd['metadata'].apply(
            lambda x: extract_first_field(x, 'Date Acquired'))
        scence_pd['satellite'] = scence_pd['metadata'].apply(
            lambda x: extract_first_field(x, 'Satellite'))

        # Drop the metadata column to not include it in the CSV
        scence_pd = scence_pd.drop('metadata', axis=1)
    else:
        print("Warning: 'metadata' column not found in API response")
        # Add placeholder columns with default values
        scence_pd['date_acquired'] = None
        scence_pd['satellite'] = None

        # Try to find date and satellite info from other columns if available
        if 'acquisitionDate' in scence_pd.columns:
            scence_pd['date_acquired'] = scence_pd['acquisitionDate']
        if 'satelliteName' in scence_pd.columns:
            scence_pd['satellite'] = scence_pd['satelliteName']

    scence_pd.to_csv(NDVI_SCENES, index=False)

    idField = 'entityId'
    entityIds = list(dict.fromkeys(scence_pd[idField].dropna().tolist()))

    entityIds = previous_undownloaded(entityIds)
    listId = f"temp_{datasetName}_list" # customized list id
    sendRequest(serviceUrl + "scene-list-remove", {"listId": listId}, apiKey, False)
    scn_list_add_payload = {
        "listId": listId,
        'idField' : idField,
        "entityIds": entityIds,
        "datasetName": datasetName
    }
    scn_list_add_payload

    count = sendRequest(serviceUrl + "scene-list-add", scn_list_add_payload, apiKey)

    sendRequest(serviceUrl + "scene-list-get", {'listId' : scn_list_add_payload['listId']}, apiKey)

    products = get_download_options(listId, datasetName, True)
    downloads = []
    seen_downloads = set()
    for product in products:
        if product["secondaryDownloads"] is not None and len(product["secondaryDownloads"]) > 0:
            for secondaryDownload in product["secondaryDownloads"]:
                for bandName in bandNames:
                    if secondaryDownload["bulkAvailable"] and bandName in secondaryDownload['displayId']:
                        item = (secondaryDownload["entityId"], secondaryDownload["id"])
                        if item not in seen_downloads:
                            seen_downloads.add(item)
                            downloads.append({
                                "entityId": secondaryDownload["entityId"],
                                "productId": secondaryDownload["id"]
                            })

    if not downloads:
        print("No band downloads available for the selected scenes")
        pd.DataFrame(columns=['displayId', 'entityId']).to_csv(UNDONE_SCENES, index=False)
        sendRequest(serviceUrl + "scene-list-remove", {"listId": listId}, apiKey, False)
        sendRequest(serviceUrl + "logout", None, apiKey)
        sys.exit(0)

    print(f"Requesting {len(downloads)} unique band downloads")
    download_req_payload = {
            "downloads": downloads,
            "label": label
        }
    download_request_results = run_download_request(download_req_payload)
    run_download_retrieve(download_request_results, out_dir)

    remove_scnlst_payload = {
        "listId": listId
    }
    sendRequest(serviceUrl + "scene-list-remove", remove_scnlst_payload, apiKey)
    endpoint = "logout"
    if sendRequest(serviceUrl + endpoint, None, apiKey) == None:
        print("\nLogged Out\n")
    else:
        print("\nLogout Failed\n")

    # Save undownloaded scenes.
    un_finised_scenes, zero_bites, unfinished_entity_ids = scene_file_downloaded(scence_pd, out_dir)
    # Keep displayId for update_ndvi.R; entityId for re-queue in this script
    df = pd.DataFrame({
        'displayId': un_finised_scenes,
        'entityId': unfinished_entity_ids + [None] * max(0, len(un_finised_scenes) - len(unfinished_entity_ids))
    }).drop_duplicates(subset=['displayId'], keep='first')
    df.to_csv(UNDONE_SCENES, index=False)
