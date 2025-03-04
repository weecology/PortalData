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
import geopandas as gpd

from datetime import datetime
from datetime import timedelta, date

import warnings
warnings.filterwarnings("ignore")


serviceUrl = "https://m2m.cr.usgs.gov/api/api/json/stable/"

bandNames = {"_SR_B4.TIF", "_SR_B5.TIF", "_QA_PIXEL.TIF"}
maxthreads = 5 # Threads count for downloads
sema = threading.Semaphore(value=maxthreads)
label = datetime.now().strftime("%Y%m%d_%H%M%S") # Customized label using date time
threads = []

NDVI_DIR = os.path.normpath(os.path.abspath(__file__ + "/../../NDVI"))
PATH = os.path.join(NDVI_DIR, "landsat-data")
NDVI_SCENES = os.path.join(NDVI_DIR, "scenes.csv")
NDVI_CSV = os.path.join(NDVI_DIR, "ndvi.csv")
UNDONE_SCENES = os.path.join(NDVI_DIR, "undone-scenes.csv")


# Send HTTP request
def sendRequest(url, data, apiKey=None, exitIfNoResponse=True):
    """
    Send a request to an M2M (Machine-to-Machine) endpoint and return the parsed JSON response.

    Parameters:
    - url (str): The URL of the M2M endpoint.
    - data (dict): The payload to be sent with the request.
    - apiKey (str, optional): An optional API key for authorization. If not provided, the request will be sent without an authorization header.
    - exitIfNoResponse (bool, optional): If True, the program will exit upon receiving an error or no response. Defaults to True.

    Returns:
    - dict: The parsed JSON response containing the data, or False if there was an error.
    """
    
    # Convert payload to json string
    json_data = json.dumps(data)
    
    if apiKey == None:
        response = requests.post(url, json_data)
    else:
        headers = {'X-Auth-Token': apiKey}              
        response = requests.post(url, json_data, headers = headers)  
    
    try:
      httpStatusCode = response.status_code 
      if response == None:
          print("No output from service")
          if exitIfNoResponse: sys.exit()
          else: return False
      output = json.loads(response.text)
      if output['errorCode'] != None:
          print(output['errorCode'], "- ", output['errorMessage'])
          if exitIfNoResponse: sys.exit()
          else: return False
      if  httpStatusCode == 404:
          print("404 Not Found")
          if exitIfNoResponse: sys.exit()
          else: return False
      elif httpStatusCode == 401: 
          print("401 Unauthorized")
          if exitIfNoResponse: sys.exit()
          else: return False
      elif httpStatusCode == 400:
          print("Error Code", httpStatusCode)
          if exitIfNoResponse: sys.exit()
          else: return False
    except Exception as e: 
          response.close()
          print(e)
          if exitIfNoResponse: sys.exit()
          else: return False
    response.close()
    
    return output['data']


def downloadFile(url, out_dir):
    sema.acquire()
    try:
        response = requests.get(url, stream=True)
        disposition = response.headers['content-disposition']
        filename = re.findall("filename=(.+)", disposition)[0].strip("\"")
        print(f"    Downloading: {filename} -- {url}...")
        
        open(os.path.join(out_dir, filename), 'wb').write(response.content)
        sema.release()
    except Exception as e:
        print(f"\nFailed to download from {url}. Will try to re-download.")
        sema.release()
        runDownload(threads, url, out_dir)


def previous_undownloaded(entityIds):
    # Add previously failed or un downloaded scenes (using new API format)
    if os.path.exists(UNDONE_SCENES):
        try:
            old_undownloaded = pd.read_csv(UNDONE_SCENES)
            failed_entities = list(old_undownloaded['displayId'])
            entityIds = list(set(entityIds + failed_entities))
        except Exception as e:
            return entityIds
    return entityIds


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
                    parsed_date = datetime.strptime(value, "%Y-%m-%d")  # or whatever format it's in
                    value = parsed_date.strftime("%Y-%m-%d")
                except:
                    pass  # Keep original format if parsing fails
            
            return value
    
    return None


def runDownload(threads, url, out_dir):
    thread = threading.Thread(target=downloadFile, args=(url,out_dir,))
    threads.append(thread)
    thread.start()


def get_last_date(ndvi_file=NDVI_CSV):
    """Get last recorded date from NDVI/ndvi.csv"""
    print(ndvi_file)
    ndvi_df = pd.read_csv(ndvi_file)
    return ndvi_df['date'].iat[-1]


# def scene_to_csv(products, scene_file=NDVI_SCENES):
#     # Convert the JSON-normalized products to a DataFrame
#     products_df = pd.json_normalize(products)
#     # Save to CSV file
#     products_df.to_csv(NDVI_SCENES, index=False)
#     print(f"CSV file saved with {len(products_df)} rows")


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

    exts = {
    "landsat_ot_c2_l2": ["_SR_B4.TIF", "_SR_B5.TIF", "_QA_PIXEL.TIF"]
    }

    all_extensions = exts[dataset.lower()]
    display_ids = scence_pd['displayId'].tolist()

    for scene in display_ids:
        if scene.strip():
            for ext in all_extensions:
                file_path = os.path.join(data_path, scene + ext)
                if os.path.isfile(file_path) and  os.stat(file_path).st_size == 0:
                    zero_bites.append(scene)
                    un_finised_scenes.append(scene)
                    print(f"Zero byte file: by scene {scene}, {file_path}")
                if not os.path.isfile(file_path):
                    un_finised_scenes.append(scene)
                    print(f"Unfinished scene: {scene}, {file_path}")
    return un_finised_scenes, zero_bites


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
    # Use requests.post() to make the login request
    response = requests.post(f"{serviceUrl}login-token", json={'username':username, 'token': token})

    if response.status_code == 200:  # Check for successful response
        apiKey = response.json()['data']
        print('\nLogin Successful, API Key Received!')
        headers = {'X-Auth-Token': apiKey}
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

    serviceUrl = "https://m2m.cr.usgs.gov/api/api/json/stable/"
    bandNames = {"_SR_B4.TIF", "_SR_B5.TIF", "_QA_PIXEL.TIF"}
    maxthreads = 5 # Threads count for downloads
    sema = threading.Semaphore(value=maxthreads)
    label = datetime.now().strftime("%Y%m%d_%H%M%S") # Customized label using date time
    threads = []

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
    search_payload = {
        'datasetName' : datasetName,
        'sceneFilter' : {
            'spatialFilter' : spatialFilter,
            'acquisitionFilter' : temporalFilter,
            'cloudCoverFilter' : cloudCoverFilter
        }
    }

    scenes = sendRequest(serviceUrl + "scene-search", search_payload, apiKey)
    print(len(scenes['results']))
    scence_pd = pd.json_normalize(scenes['results'])
    
    # Extract 'Date Acquired' and 'Satellite' from metadata
    scence_pd['date_acquired'] = scence_pd['metadata'].apply(
        lambda x: extract_first_field(x, 'Date Acquired'))
    scence_pd['satellite'] = scence_pd['metadata'].apply(
        lambda x: extract_first_field(x, 'Satellite'))
    
    # Drop the metadata column to not include it in the CSV
    if 'metadata' in scence_pd.columns:
        scence_pd = scence_pd.drop('metadata', axis=1)
    
    scence_pd.to_csv(NDVI_SCENES, index=False)

    idField = 'entityId'
    entityIds = []
    for result in scenes['results']:
            entityIds.append(result[idField])
        
    entityIds = previous_undownloaded(entityIds)
    listId = f"temp_{datasetName}_list" # customized list id
    scn_list_add_payload = {
        "listId": listId,
        'idField' : idField,
        "entityIds": entityIds,
        "datasetName": datasetName
    }
    scn_list_add_payload

    count = sendRequest(serviceUrl + "scene-list-add", scn_list_add_payload, apiKey) 
    
    sendRequest(serviceUrl + "scene-list-get", {'listId' : scn_list_add_payload['listId']}, apiKey) 

    products = get_download_options(listId, datasetName, False)
    downloads = []
    for product in products:  
        if product["secondaryDownloads"] is not None and len(product["secondaryDownloads"]) > 0:
            for secondaryDownload in product["secondaryDownloads"]:
                for bandName in bandNames:
                    if secondaryDownload["bulkAvailable"] and bandName in secondaryDownload['displayId']:
                        downloads.append({"entityId":secondaryDownload["entityId"], "productId":secondaryDownload["id"]})

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

  

    # Save un downloaded scenes.
    un_finised_scenes, zero_bites = scene_file_downloaded(scence_pd, out_dir)
    unique_ids = list(set(un_finised_scenes))
    # dictionary of un downloaded entity ids or scenes
    undone_ids = {'displayId': unique_ids}
    df = pd.DataFrame(undone_ids)
    df.to_csv(UNDONE_SCENES, index=False)
